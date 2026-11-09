use strict;
use warnings;
use Test::More;

# Offline tripwire for karr k29: DBIO::DB2::Deploy::_split_qualify_ddl is a
# pure string transform -- it takes the install DDL and re-points every object
# at the throwaway compare schema DBIO_TEST_<pid> -- and it had no test at all,
# which is why it silently stopped working.
#
# Since karr k28 DBIO::DB2::DDL quotes every identifier, so the statements this
# function rewrites read CREATE TABLE "author", not CREATE TABLE author. The
# qualifier still matched a bare \w+, which cannot match a leading `"`: not one
# of its five substitutions fired, and _build_target_model then ran the WHOLE
# compare DDL unqualified against CURRENT SCHEMA -- i.e. re-deployed the desired
# schema straight into the LIVE database (SQL0601N on the normal upgrade path,
# silent pollution otherwise).
#
# The assertions below therefore do not check that the output "looks
# qualified": they take every statement install_ddl emitted and require the
# object position to carry the DBIO_TEST_<pid> prefix, and separately require
# that no unqualified object position survives anywhere. Reverting the regex to
# \w+ turns every one of them red.
#
# karr k35 is the remaining half of the same fault. install_ddl also emits
# CREATE VIEW, and _split_qualify_ddl covered no view at all -- so a schema with
# a view put its compare view straight into the LIVE schema. A view has TWO
# positions, not one: the name, which is an object position like any other, and
# the BODY, which is the user's own view_definition and cannot be rewritten by a
# regex pass whose licence is that it only ever sees SQL this distribution wrote
# itself. Qualifying just the name would be worse than the bug -- the compare
# view would sit in the compare schema while its FROM still resolved against the
# LIVE tables, and the diff would compare two unlike objects. So the body is
# passed through untouched and _build_target_model points CURRENT SCHEMA at the
# compare schema for the duration of the deploy instead. This file pins both
# halves: the name rewrite (offline, textual) and the register bracketing
# (offline, against a recording handle).

use_ok 'DBIO::DB2::DDL';
use_ok 'DBIO::DB2::Deploy';

# ---------------------------------------------------------------------------
# A two-table schema with a belongs_to FK (so the REFERENCES branch is
# exercised) plus one UNIQUE and one plain index on the child (CREATE UNIQUE
# INDEX was never covered by the old CREATE INDEX branch, even before k28).
# ---------------------------------------------------------------------------
{
  package My::Qualify::Schema::Author;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('author');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 255 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many('books', 'My::Qualify::Schema::Book', 'author_id');
}

{
  package My::Qualify::Schema::Book;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('book');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    author_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 255 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to('author', 'My::Qualify::Schema::Author', 'author_id');
  sub db2_indexes {
    return {
      idx_book_author_id => { unique => 0, columns => ['author_id'] },
      uidx_book_title    => { unique => 1, columns => ['title'] },
    };
  }
}

# A non-virtual view over both tables. Its body names "book" and "author"
# UNQUALIFIED -- which is the whole point: that text must survive the qualifier
# byte for byte, and be made to mean the compare tables by CURRENT SCHEMA
# rather than by rewriting. (A virtual view emits no DDL at all and would make
# the view assertions below vacuous, so this one is deliberately not virtual.)
my $VIEW_BODY = q{SELECT "book"."id" AS "book_id", "author"."name" AS "author_name" }
              . q{FROM "book" JOIN "author" ON "book"."author_id" = "author"."id"};

{
  package My::Qualify::Schema::BookAuthor;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('book_author');
  __PACKAGE__->result_source_instance->view_definition($VIEW_BODY);
  __PACKAGE__->add_columns(
    book_id     => { data_type => 'integer' },
    author_name => { data_type => 'varchar', size => 255 },
  );
}

{
  package My::Qualify::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Author     => 'My::Qualify::Schema::Author');
  __PACKAGE__->register_class(Book       => 'My::Qualify::Schema::Book');
  __PACKAGE__->register_class(BookAuthor => 'My::Qualify::Schema::BookAuthor');
}

my $TEST_SCHEMA = 'DBIO_TEST_' . $$;   # exactly what _build_target_model uses
my $ddl = DBIO::DB2::DDL->install_ddl('My::Qualify::Schema');

# ---------------------------------------------------------------------------
# The fixture really carries the four shapes under test. Without this, a DDL
# generator that stopped emitting the FK or the unique index would let every
# assertion below pass vacuously.
# ---------------------------------------------------------------------------
like $ddl, qr/CREATE TABLE "author"/,       'fixture DDL creates the parent table (quoted)';
like $ddl, qr/CREATE TABLE "book"/,         'fixture DDL creates the child table (quoted)';
like $ddl, qr/REFERENCES "author"\("id"\)/, 'fixture DDL carries an inline REFERENCES clause';
like $ddl, qr/CREATE UNIQUE INDEX "uidx_book_title"/,
  'fixture DDL carries a CREATE UNIQUE INDEX';
like $ddl, qr/CREATE INDEX "idx_book_author_id"/,
  'fixture DDL carries a plain CREATE INDEX';
like $ddl, qr/CREATE VIEW "book_author" AS \Q$VIEW_BODY\E;/,
  'fixture DDL carries a CREATE VIEW with an unqualified body';

my @stmts = DBIO::DB2::Deploy->_split_qualify_ddl($ddl, $TEST_SCHEMA);

# ---------------------------------------------------------------------------
# Every statement's object position is qualified onto the compare schema.
# ---------------------------------------------------------------------------
my @objects;
for my $stmt (@stmts) {
  my ($head) = $stmt =~ /\A(.{0,60})/s;
  $head =~ s/\s+/ /g;

  # What this claims (and still claims): EVERY statement install_ddl emitted is
  # one of the shapes whose object position the qualifier knows how to rewrite.
  # It is the anti-vacuity guard for the `next unless defined $kw` below -- a
  # statement in an unrecognised shape would otherwise skip the qualification
  # check in silence, and the file would pass while covering nothing.
  #
  # CREATE VIEW is ADDED to the recognised set here, not exempted from it: the
  # view statement now goes through the very same `like $obj, ...` check and
  # into the very same exhaustive @objects list as every other statement. The
  # claim is unchanged -- it is the set of shapes the qualifier handles that
  # grew, by exactly the shape it was taught in karr k35. Anything that is
  # neither table, index nor view is still a failure here, which is what it
  # should be: a new emitted shape needs a new substitution, not a wider regex.
  my ($kw, $obj) = $stmt =~ m{
    \A ( CREATE (?: \s+ UNIQUE )? \s+ (?: TABLE | INDEX )
       | CREATE \s+ VIEW
       | DROP \s+ (?: TABLE | INDEX ) ) \s+ (\S+)
  }x;
  ok defined $kw, "statement is a known DDL shape: $head";
  next unless defined $kw;

  like $obj, qr/\A\Q$TEST_SCHEMA\E\."/,
    "$kw target is qualified onto the compare schema (got $obj)";
  push @objects, $obj;
}

is_deeply [ sort @objects ],
  [ sort map { qq{$TEST_SCHEMA."$_"} }
      qw( author book book_author idx_book_author_id uidx_book_title ) ],
  'every object install_ddl emits is qualified, and none is missing';

# ---------------------------------------------------------------------------
# ... and no unqualified object position survives ANYWHERE. This is the
# assertion the old \w+ regex fails on the very first statement: it leaves
# CREATE TABLE "author" untouched, which is a quoted name with no schema in
# front of it.
# ---------------------------------------------------------------------------
for my $stmt (@stmts) {
  my ($head) = $stmt =~ /\A(.{0,40})/s;
  $head =~ s/\s+/ /g;

  unlike $stmt, qr/(?:CREATE|DROP)\s+(?:UNIQUE\s+)?(?:TABLE|INDEX)\s+"/,
    "no unqualified CREATE/DROP target left in: $head";
  unlike $stmt, qr/\bINDEX\s+\S+\s+ON\s+"/,
    "no unqualified CREATE INDEX ... ON target left in: $head";
  unlike $stmt, qr/\bREFERENCES\s+"/,
    "no unqualified REFERENCES target left in: $head";
  unlike $stmt, qr/\ACREATE\s+VIEW\s+"/,
    "no unqualified CREATE VIEW target left in: $head";
}

# The FK target must point at the compare schema's parent, not the live one --
# an unqualified REFERENCES resolves against CURRENT SCHEMA and would make the
# throwaway child cross-reference the LIVE parent table.
my ($book_stmt) = grep { /CREATE TABLE \Q$TEST_SCHEMA\E\."book"/ } @stmts;
ok $book_stmt, 'the child CREATE TABLE is among the qualified statements';
like $book_stmt, qr/REFERENCES \Q$TEST_SCHEMA\E\."author"\("id"\)/,
  'the inline FK REFERENCES the compare schema parent, not the live one';

# ---------------------------------------------------------------------------
# The view: the NAME moved, the BODY did not. Both halves are the assertion.
#
# A body that had been rewritten would be the "half fix" this whole design
# rejects, and it would fail here as loudly as a body left unqualified in a
# world without the CURRENT SCHEMA leg -- because the body is compared to the
# view_definition the fixture handed in, character for character.
# ---------------------------------------------------------------------------
my ($view_stmt) = grep { /\ACREATE VIEW / } @stmts;
ok $view_stmt, 'the CREATE VIEW is among the qualified statements';
like $view_stmt, qr/\ACREATE VIEW \Q$TEST_SCHEMA\E\."book_author" AS /,
  'the view NAME is qualified onto the compare schema';
is +($view_stmt =~ /\ACREATE VIEW \S+ AS (.*)\z/s ? $1 : undef), $VIEW_BODY,
  'the view BODY is passed through verbatim -- the pass does not parse user SQL';
like $view_stmt, qr/FROM "book" JOIN "author"/,
  '... so its table references are still bare, and mean whatever CURRENT SCHEMA says';

# ---------------------------------------------------------------------------
# Compatibility: a hand-fed script from before the always-quote change carries
# bare identifiers. Those are still qualified, so a regression in the quoting
# half cannot silently route the compare deploy back into the live schema.
# ---------------------------------------------------------------------------
{
  my @bare = DBIO::DB2::Deploy->_split_qualify_ddl(<<'SQL', $TEST_SCHEMA);
CREATE TABLE legacy (id INTEGER NOT NULL);
CREATE UNIQUE INDEX legacy_idx ON legacy (id);
DROP INDEX legacy_idx;
DROP TABLE legacy;
SQL
  is_deeply \@bare, [
    "CREATE TABLE $TEST_SCHEMA.legacy (id INTEGER NOT NULL)",
    "CREATE UNIQUE INDEX $TEST_SCHEMA.legacy_idx ON $TEST_SCHEMA.legacy (id)",
    "DROP INDEX $TEST_SCHEMA.legacy_idx",
    "DROP TABLE $TEST_SCHEMA.legacy",
  ], 'bare (pre-k28) identifiers are qualified too';
}

# Comment lines are not statements. Since dbio k326 the core splitter takes a
# leading comment off the statement it precedes, so a comment-only chunk no
# longer comes out of it -- and a statement behind a comment line is
# qualified like any other (karr k49). Before, the core dropped that
# statement silently (it only ever saw it as a piece starting with "--").
{
  my @c = DBIO::DB2::Deploy->_split_qualify_ddl("-- CREATE TABLE \"x\"\n", $TEST_SCHEMA);
  is_deeply \@c, [], 'a comment-only DDL yields no statement';

  my @n = DBIO::DB2::Deploy->_split_qualify_ddl(
    qq{-- note\nCREATE TABLE "x" (id INTEGER NOT NULL);\n-- tail\n}, $TEST_SCHEMA);
  is_deeply \@n, [ qq{CREATE TABLE $TEST_SCHEMA."x" (id INTEGER NOT NULL)} ],
    'a statement behind a comment line is qualified, the comment is gone';
}

# ---------------------------------------------------------------------------
# The other half of karr k35: what the bare "book"/"author" in that body MEAN.
#
# Nothing in the statement text says, so the answer has to come from CURRENT
# SCHEMA, and _build_target_model is what has to set it. Offline: no server, no
# DBD::DB2 -- a recording handle in place of the connection, and the real
# _build_target_model driven over it. The handle notes, per statement, which
# schema was in effect when it ran, so the assertion can be the actual claim
# ("the CREATE VIEW ran with CURRENT SCHEMA on the compare schema") rather than
# a proxy for it ("a SET statement appears somewhere earlier in the list").
#
# The live behaviour this rests on -- Db2 qualifying unqualified references in a
# dynamically prepared CREATE VIEW with CURRENT SCHEMA -- is documented Db2, but
# no server was available to confirm it here.
# ---------------------------------------------------------------------------
{
  package Qualify::Dbh;
  sub new { bless { do => [], at => [], schema => 'LiveSchema', die_on => $_[1] }, $_[0] }
  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{do} }, $sql;
    push @{ $self->{at} }, $self->{schema};   # in effect FOR this statement
    die "mock handle refused: $sql\n" if $self->{die_on} && $sql =~ $self->{die_on};
    $self->{schema} = $1 if $sql =~ /\ASET CURRENT SCHEMA = '(.*)'\z/;
    return 1;
  }
  # CURRENT SCHEMA comes back CHAR(128), space-padded -- the padding must not
  # travel into the string constant the restore builds.
  sub selectrow_array {
    my ($self, $sql) = @_;
    return ($self->{schema} . (' ' x 12)) if $sql =~ /CURRENT SCHEMA/;
    return ();                       # the leftover-compare-schema probe: none
  }
  sub selectall_arrayref { [] }      # the teardown catalog reads: empty schema
}
{
  package Qualify::Introspect;
  sub new   { bless {}, shift }
  sub model { { tables => {}, columns => {}, indexes => {}, foreign_keys => {} } }
}
{
  package Qualify::Deploy;
  use base 'DBIO::DB2::Deploy';
  sub _dbh            { $_[0]{dbh} }              # no storage, no connection
  sub _new_introspect { Qualify::Introspect->new } # SYSCAT is not what is under test
}

{
  my $dbh = Qualify::Dbh->new;
  my $model = Qualify::Deploy->new(schema => 'My::Qualify::Schema', dbh => $dbh)
                             ->_build_target_model;
  ok $model, 'the compare deploy ran through and produced a target model';

  is $dbh->{do}[0], "CREATE SCHEMA $TEST_SCHEMA",
    'the compare schema is created first';
  is $dbh->{do}[1], "SET CURRENT SCHEMA = '$TEST_SCHEMA'",
    '... and the register is moved onto it before any DDL runs';

  # The claim, per statement: every object the compare deploy created was
  # created with CURRENT SCHEMA on the compare schema. For the CREATE VIEW that
  # is what makes its unqualified body mean the compare tables; for the rest it
  # is belt to the qualifier's braces.
  my @ddl = grep { $dbh->{do}[$_] =~ /\ACREATE (?:TABLE|VIEW|UNIQUE INDEX|INDEX) / }
              0 .. $#{ $dbh->{do} };
  is scalar @ddl, 5, 'all five install statements reached the handle';
  for my $i (@ddl) {
    my ($head) = $dbh->{do}[$i] =~ /\A(.{0,45})/s;
    is $dbh->{at}[$i], $TEST_SCHEMA,
      "ran with CURRENT SCHEMA on the compare schema: $head";
  }

  my ($view_i) = grep { $dbh->{do}[$_] =~ /\ACREATE VIEW / } 0 .. $#{ $dbh->{do} };
  ok defined $view_i, 'the CREATE VIEW reached the handle';
  like $dbh->{do}[$view_i], qr/FROM "book" JOIN "author"/,
    '... with its body still unqualified, resolved by the register alone';

  is $dbh->{do}[-2], "SET CURRENT SCHEMA = 'LiveSchema'",
    'the saved schema is put back, right-trimmed, before the teardown';
  is $dbh->{do}[-1], "DROP SCHEMA $TEST_SCHEMA RESTRICT",
    '... and the compare schema is dropped afterwards';
  is $dbh->{schema}, 'LiveSchema',
    'the shared handle ends the run on the schema it started on';
}

# The register must come back on the FAILURE path too -- the handle is the live
# storage's own, and leaving it on a schema this method then drops would
# mis-resolve every later unqualified statement. The build error is what must
# surface, not a teardown error and not a silent undef: every eval below the
# build blanks $@, so the error has to be captured before they run.
{
  my $dbh = Qualify::Dbh->new(qr/\ACREATE VIEW /);
  my $deploy = Qualify::Deploy->new(schema => 'My::Qualify::Schema', dbh => $dbh);
  my $model = eval { $deploy->_build_target_model };
  my $err = $@;

  ok !$model, 'a failed compare deploy yields no model';
  like $err, qr/\Amock handle refused: CREATE VIEW /,
    '... and the BUILD error surfaces, not a blanked $@ or a teardown error';
  is $dbh->{do}[-2], "SET CURRENT SCHEMA = 'LiveSchema'",
    '... with the register restored anyway';
  is $dbh->{schema}, 'LiveSchema',
    '... so the live connection is not left on the dropped compare schema';
  is $dbh->{do}[-1], "DROP SCHEMA $TEST_SCHEMA RESTRICT",
    '... and the compare schema still torn down';
}

# A CURRENT SCHEMA that cannot be read is a run that must not start: without it
# there is no value to put back on the shared handle, so the refusal has to come
# BEFORE the first side effect rather than after a schema has been created.
{
  package Qualify::Dbh::Mute;
  our @ISA = ('Qualify::Dbh');
  sub selectrow_array { return () }
}
{
  my $dbh = Qualify::Dbh::Mute->new;
  my $deploy = Qualify::Deploy->new(schema => 'My::Qualify::Schema', dbh => $dbh);
  ok !eval { $deploy->_build_target_model; 1 },
    'an unreadable CURRENT SCHEMA refuses the compare deploy';
  like $@, qr/cannot read CURRENT SCHEMA/,
    '... naming the register it could not read';
  is_deeply $dbh->{do}, [],
    '... before creating anything, so no compare schema is leaked';
}

done_testing;
