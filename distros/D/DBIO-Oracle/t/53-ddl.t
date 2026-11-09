use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok 'DBIO::Oracle::DDL';
use DBIO::Oracle::Identifier;

# Offline DDL test: DBIO::Oracle::DDL::install_ddl renders the nullability
# clause from the column_info is_nullable key. A missing key means NOT NULL
# (ADR 0043, core k147): canonical_column folds a missing is_nullable into
# not_null => 1, so the emitted DDL must agree with the compiled model.
# No live database -- a mock schema supplies the column_info.

{
  package Mock::Source;
  sub new { bless { %{ $_[1] // {} } }, $_[0] }
  sub name { $_[0]->{name} }
  sub columns { @{ $_[0]->{columns} } }
  sub column_info { $_[0]->{column_info}{ $_[1] } }
  sub primary_columns { @{ $_[0]->{primary_columns} // [] } }
  sub unique_constraints { %{ $_[0]->{unique_constraints} // {} } }
}

{
  package Mock::Schema;
  sub new { bless { sources => $_[1] }, $_[0] }
  sub sources { keys %{ $_[0]->{sources} } }
  sub source { $_[0]->{sources}{ $_[1] } }
}

my $schema = Mock::Schema->new({
  t => Mock::Source->new({
    name    => 't',
    columns => [qw/plain hard soft/],
    column_info => {
      plain => { data_type => 'varchar', size => 10 },            # no is_nullable
      hard  => { data_type => 'varchar', size => 10, is_nullable => 0 },
      soft  => { data_type => 'varchar', size => 10, is_nullable => 1 },
    },
    primary_columns => [],
  }),
});

my $ddl = DBIO::Oracle::DDL->install_ddl($schema);

like($ddl, qr/"plain" VARCHAR2\(10\) NOT NULL/,
  'missing is_nullable deploys NOT NULL');
like($ddl, qr/"hard" VARCHAR2\(10\) NOT NULL/,
  'is_nullable => 0 deploys NOT NULL');
like($ddl, qr/"soft" VARCHAR2\(10\)/,
  'is_nullable => 1 column present');
unlike($ddl, qr/"soft" VARCHAR2\(10\) NOT NULL/,
  'is_nullable => 1 stays nullable');

# A column that is NOT NULL and has a default (karr k45). Oracle's column
# definition is "datatype [DEFAULT expr] [inline_constraint ...]": the default
# comes first. The server refuses the other order, and with it the whole
# CREATE TABLE (ORA-03076 on 23.26, measured in t/54-deploy-live.t, 1e).
{
  my $defaulted = Mock::Schema->new({
    d => Mock::Source->new({
      name    => 'd',
      columns => [qw/code n twice note/],
      column_info => {
        code  => { data_type => 'varchar', size => 20, is_nullable => 0, default_value => 'x' },
        n     => { data_type => 'integer', is_nullable => 0, default_value => 0 },
        twice => { data_type => 'integer', is_nullable => 0, default_value => \'1 + 1' },
        note  => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => 'none' },
      },
      primary_columns => [],
    }),
  });

  my $ddl = DBIO::Oracle::DDL->install_ddl($defaulted);

  like($ddl, qr/^\s*"code" VARCHAR2\(20\) DEFAULT 'x' NOT NULL,$/m,
    'a literal default is written before NOT NULL');
  like($ddl, qr/^\s*"n" INTEGER DEFAULT 0 NOT NULL,$/m,
    '... a false one (0) as well, and a number is not quoted (karr k47)');
  like($ddl, qr/^\s*"twice" INTEGER DEFAULT 1 \+ 1 NOT NULL,$/m,
    '... and so is an expression default (scalar ref)');
  like($ddl, qr/^\s*"note" VARCHAR2\(20\) DEFAULT 'none'$/m,
    'a nullable column keeps its default and gets no NOT NULL');
  unlike($ddl, qr/NOT NULL\s+DEFAULT/,
    'no column definition has NOT NULL in front of DEFAULT');
}

# The value of a default is written as a SQL literal (karr k47). A string
# carries its apostrophes doubled -- "it's" used to come out as 'it's', which
# the server cannot parse -- and a number is not quoted, so that the default
# the introspector reads back (Introspect::Columns) is the one declared.
{
  my $schema = Mock::Schema->new({
    lit => Mock::Source->new({
      name    => 'lit',
      columns => [qw/apos quotes num neg frac zeros trail expr/],
      column_info => {
        apos   => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => "it's" },
        quotes => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => "'" },
        num    => { data_type => 'integer', is_nullable => 1, default_value => 42 },
        neg    => { data_type => 'integer', is_nullable => 1, default_value => -3 },
        frac   => { data_type => 'numeric', size => [5, 2], is_nullable => 1, default_value => 0.5 },
        # strings that look like numbers but would change as numbers
        zeros  => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => '007' },
        trail  => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => '1.50' },
        expr   => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => \"'it''s'" },
      },
      primary_columns => [],
    }),
  });
  my $ddl = DBIO::Oracle::DDL->install_ddl($schema);

  like($ddl, qr/^\s*"apos" VARCHAR2\(20\) DEFAULT 'it''s',$/m,
    'an apostrophe in a string default is doubled');
  like($ddl, qr/^\s*"quotes" VARCHAR2\(20\) DEFAULT '''',$/m,
    '... a lone apostrophe as well');
  like($ddl, qr/^\s*"num" INTEGER DEFAULT 42,$/m,    'a number default is not quoted');
  like($ddl, qr/^\s*"neg" INTEGER DEFAULT -3,$/m,    '... nor a negative one');
  like($ddl, qr/^\s*"frac" NUMBER\(5,2\) DEFAULT 0\.5,$/m, '... nor a fraction');
  like($ddl, qr/^\s*"zeros" VARCHAR2\(20\) DEFAULT '007',$/m,
    'a string that only looks like a number keeps its quotes (007 is not 7)');
  like($ddl, qr/^\s*"trail" VARCHAR2\(20\) DEFAULT '1\.50',$/m,
    '... and so does 1.50 (it is not 1.5)');
  like($ddl, qr/^\s*"expr" VARCHAR2\(20\) DEFAULT 'it''s'$/m,
    'a scalar ref is written as it stands');
}

# The unique constraints of a source (add_unique_constraint, Cake uniq) are
# written as CONSTRAINT .. UNIQUE (karr k46). They used to be ignored: the
# only code that made a unique index looked at a column_info flag nobody sets,
# so find_or_create over such a key was not protected against duplicates.
{
  package T::K46::Row;
  use base 'DBIO::Core';
  __PACKAGE__->table('k46_row');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    code => { data_type => 'varchar', size => 10 },
    a    => { data_type => 'integer' },
    b    => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(r_code => ['code']);
  __PACKAGE__->add_unique_constraint(r_pair => [qw(a b)]);
  # the same columns as the primary key: Oracle refuses it a second time
  __PACKAGE__->add_unique_constraint(r_pk_again => ['id']);
  # a second one over the same columns as r_code
  __PACKAGE__->add_unique_constraint(r_code_twice => ['code']);

  package T::K46;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Row => 'T::K46::Row');
}

{
  my $ddl = DBIO::Oracle::DDL->install_ddl('T::K46');

  like($ddl, qr/^\s*CONSTRAINT "r_code" UNIQUE \("code"\)/m,
    'a one-column unique constraint is written (karr k46)');
  like($ddl, qr/^\s*CONSTRAINT "r_pair" UNIQUE \("a", "b"\)/m,
    '... and a two-column one, in the declared column order');
  unlike($ddl, qr/CONSTRAINT "r_pk_again"/,
    'a unique constraint over exactly the primary key is not written again (ORA-02261)');
  unlike($ddl, qr/CONSTRAINT "r_code_twice"/,
    '... nor a second one over the same columns as an earlier one');
  unlike($ddl, qr/UNIQUE \("id"\)|CONSTRAINT primary/i,
    'the primary constraint itself is the PRIMARY KEY, not a UNIQUE');
  like($ddl, qr/PRIMARY KEY \("id"\),\n\s*CONSTRAINT "r_code" UNIQUE/,
    '... and the constraints sit inside the CREATE TABLE, after the primary key');
  unlike($ddl, qr/CREATE UNIQUE INDEX/,
    'no separate unique index is made for them');

  # an mock source with a long name: shortened like every generated name
  my $long = Mock::Schema->new({ t => Mock::Source->new({
    name => 't', columns => ['c'],
    column_info => { c => { data_type => 'varchar', size => 5 } },
    unique_constraints => { 'a_very_long_unique_constraint_name_beyond_30' => ['c'] },
  }) });
  my ($cname) = DBIO::Oracle::DDL->install_ddl($long) =~ /CONSTRAINT "([^"]+)" UNIQUE/;
  cmp_ok length($cname), '<=', 30, 'a constraint name over 30 characters is shortened';
}

# An index declaration (Cake idx, indices) that meets a unique constraint --
# by name, or over exactly its columns -- is refused with an exception naming
# both; Oracle would answer the second with ORA-01408 and the first would
# silently displace the constraint (karr k46).
{
  my $n = 0;
  my $build = sub {
    my ($decl) = @_;
    $n++;
    my ($schema, $class) = ("T::K46I$n", "T::K46I$n\::Row");
    eval qq{
      package $schema; use base 'DBIO::Schema';
      package $class; use base 'DBIO::Core';
      $class->table('k46_idx');
      $class->add_columns(id => { data_type => 'integer' },
        code => { data_type => 'varchar', size => 10 }, a => { data_type => 'integer' },
        b => { data_type => 'integer' });
      $class->set_primary_key('id');
      $class->add_unique_constraint(uq_code => ['code']);
      $class->add_unique_constraint(uq_pair => [qw(a b)]);
      1;
    } or die $@;
    $class->result_source_instance->add_index_declaration($decl);
    $schema->register_class(Row => $class);
    return sub { DBIO::Oracle::DDL->install_ddl($schema) };
  };

  throws_ok { $build->({ name => 'uq_code', columns => ['a'] })->() }
    qr/index 'uq_code'.*constraint 'uq_code'/s,
    'an index named like a unique constraint is refused, not preferred';
  throws_ok { $build->({ name => 'by_code', columns => ['code'] })->() }
    qr/index 'by_code'.*constraint 'uq_code'/s,
    'an index over exactly the columns of a unique constraint is refused, naming both';
  throws_ok { $build->({ name => 'by_pair', columns => [qw(a b)], unique => 1 })->() }
    qr/index 'by_pair'.*constraint 'uq_pair'/s,
    '... also a unique one, over several columns';
  lives_ok { $build->({ name => 'by_pair_rev', columns => [qw(b a)] })->() }
    'the same columns in another order are a different index and stay';
  lives_ok { $build->({ name => 'by_lower', columns => ['code'],
      driver => { oracle => { expression => 'LOWER("code")' } } })->() }
    'a function-based index is not on the constraint columns';
  lives_ok { $build->({ name => 'by_a', columns => ['a'] })->() }
    'an index over other columns is fine';
}

# Names are written quoted, exactly as the result class spells them, because
# the storage quotes with '"' and asks the dictionary for that spelling
# (karr k42); an auto-increment column gets its sequence and the BEFORE INSERT
# trigger the storage's sequence detection reads; belongs_to becomes a FOREIGN
# KEY after every table.
{
  package T::K42::Author;
  use base 'DBIO::Core';
  __PACKAGE__->table('K42_Author');
  __PACKAGE__->add_columns(
    Id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('Id');

  package T::K42::Book;
  use base 'DBIO::Core';
  __PACKAGE__->table('k42_book');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    author_id => { data_type => 'integer' },
    a_very_long_column_name_for_the_fk => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(author => 'T::K42::Author', 'author_id');
  # a second relationship over the same columns is the same constraint
  __PACKAGE__->belongs_to(author_again => 'T::K42::Author', 'author_id');
  # not a foreign key constraint: no ALTER TABLE
  __PACKAGE__->belongs_to(soft => 'T::K42::Author',
    { 'foreign.Id' => 'self.a_very_long_column_name_for_the_fk' },
    { is_foreign_key_constraint => 0 });

  package T::K42;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Author => 'T::K42::Author');
  __PACKAGE__->register_class(Book   => 'T::K42::Book');
}

{
  my $ddl = DBIO::Oracle::DDL->install_ddl('T::K42');

  like($ddl, qr/^CREATE TABLE "K42_Author" \(\n\s*"Id" INTEGER NOT NULL,\n\s*"name" VARCHAR2\(20\),\n\s*PRIMARY KEY \("Id"\)/m,
    'table and column names are quoted and keep their case (karr k42)');
  unlike($ddl, qr/^\s*(?:CREATE|ALTER) (?:TABLE|SEQUENCE|TRIGGER|INDEX) [^"]/m,
    '... and so is every other object the DDL names');

  like($ddl, qr/^CREATE SEQUENCE "K42_Author_Id_seq";$/m,
    'an auto-increment column gets a sequence, quoted like the rest');
  my $trigger = <<'SQL';
CREATE OR REPLACE TRIGGER "K42_Author_Id_trg"
BEFORE INSERT ON "K42_Author" FOR EACH ROW WHEN (new."Id" IS NULL)
BEGIN
  SELECT "K42_Author_Id_seq".NEXTVAL INTO :new."Id" FROM DUAL;
END;
SQL
  chomp $trigger;
  cmp_ok(index($ddl, $trigger), '>=', 0,
    '... and the BEFORE INSERT trigger that fills the column from it');

  my @fk = $ddl =~ /^(ALTER TABLE .*)$/mg;
  is_deeply \@fk, [
    'ALTER TABLE "k42_book" ADD CONSTRAINT "' . DBIO::Oracle::Identifier::shorten('fk_k42_book_author_id_K42_Author') . '" FOREIGN KEY ("author_id") REFERENCES "K42_Author" ("Id");',
  ], 'belongs_to becomes one FOREIGN KEY (two relationships over the same columns are one; '
   . 'a relationship that is not a foreign key constraint is none)';
  cmp_ok index($ddl, $fk[0]), '>', rindex($ddl, 'CREATE TABLE'),
    '... written after every CREATE TABLE';

  # the constraint name is shortened like every generated name
  my ($fkname) = $ddl =~ /ADD CONSTRAINT "([^"]+)"/;
  cmp_ok length($fkname), '<=', 30, 'the constraint name fits 30 characters';
  my $longname = DBIO::Oracle::Identifier::shorten('fk_k42_book_a_very_long_column_name_for_the_fk');
  cmp_ok length($longname), '<=', 30, '... also for a long column name';
}

# The actions of a foreign key (karr k42): on_delete / is_deferrable as the
# belongs_to declares them, on_delete detected from the has_many on the other
# side when it is not declared, on_update refused (Oracle has none).
{
  package T::K42A::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('k42a_parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(kids => 'T::K42A::Kid', 'parent_id');
  __PACKAGE__->has_many(quiet => 'T::K42A::Quiet', 'parent_id', { cascade_delete => 0 });

  package T::K42A::Other;
  use base 'DBIO::Core';
  __PACKAGE__->table('k42a_other');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');

  package T::K42A::Kid;
  use base 'DBIO::Core';
  __PACKAGE__->table('k42a_kid');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    parent_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  # not declared: found on Parent->kids (cascade_delete by default)
  __PACKAGE__->belongs_to(parent => 'T::K42A::Parent', 'parent_id');

  package T::K42A::Quiet;
  use base 'DBIO::Core';
  __PACKAGE__->table('k42a_quiet');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    parent_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'T::K42A::Parent', 'parent_id');

  package T::K42A::Nulled;
  use base 'DBIO::Core';
  __PACKAGE__->table('k42a_nulled');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    parent_id => { data_type => 'integer', is_nullable => 1 },
    other_id  => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'T::K42A::Parent', 'parent_id',
    { on_delete => 'set null', is_deferrable => 1, on_update => 'NO ACTION' });
  __PACKAGE__->belongs_to(other => 'T::K42A::Other', 'other_id',
    { on_delete => undef });
  # the same column, a second target: a second constraint of its own name
  __PACKAGE__->belongs_to(other_too => 'T::K42A::Other', { 'foreign.id' => 'self.parent_id' },
    { on_delete => '' });

  package T::K42A;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class($_ => "T::K42A::$_") for qw(Parent Other Kid Quiet Nulled);

  package T::K42B::Kid;
  use base 'DBIO::Core';
  __PACKAGE__->table('k42b_kid');
  __PACKAGE__->add_columns(id => { data_type => 'integer' }, p => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'T::K42A::Parent', 'p', { on_update => 'CASCADE' });

  package T::K42B;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Parent => 'T::K42A::Parent');
  __PACKAGE__->register_class(Kid => 'T::K42B::Kid');

  package T::K42C::Kid;
  use base 'DBIO::Core';
  __PACKAGE__->table('k42c_kid');
  __PACKAGE__->add_columns(id => { data_type => 'integer' }, p => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'T::K42A::Parent', 'p', { on_delete => 'SET DEFAULT' });

  package T::K42C;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Parent => 'T::K42A::Parent');
  __PACKAGE__->register_class(Kid => 'T::K42C::Kid');
}

{
  my $ddl = DBIO::Oracle::DDL->install_ddl('T::K42A');
  my %fk;
  for ($ddl =~ /^(ALTER TABLE .*)$/mg) {
    my ($t, $n, $rest) = /ALTER TABLE "(\w+)" ADD CONSTRAINT "(\w+)" (.*);\z/ or next;
    push @{ $fk{$t} }, [ $n, $rest ];
  }

  is_deeply [ map { $_->[1] } @{ $fk{k42a_kid} } ],
    [ 'FOREIGN KEY ("parent_id") REFERENCES "k42a_parent" ("id") ON DELETE CASCADE' ],
    'a belongs_to that declares no on_delete is ON DELETE CASCADE when the has_many on the other side cascades (karr k42)';
  is_deeply [ map { $_->[1] } @{ $fk{k42a_quiet} } ],
    [ 'FOREIGN KEY ("parent_id") REFERENCES "k42a_parent" ("id")' ],
    '... and has no action when that has_many has cascade_delete => 0';

  my %n = map { $_->[1] =~ /FOREIGN KEY \("(\w+)"\) REFERENCES "(\w+)"/ ? ("$1>$2" => $_) : () }
    @{ $fk{k42a_nulled} };
  is $n{'parent_id>k42a_parent'}[1],
    'FOREIGN KEY ("parent_id") REFERENCES "k42a_parent" ("id") ON DELETE SET NULL DEFERRABLE',
    'a declared on_delete (any letter case) and is_deferrable are written; on_update NO ACTION is no clause';
  is $n{'other_id>k42a_other'}[1], 'FOREIGN KEY ("other_id") REFERENCES "k42a_other" ("id")',
    'on_delete => undef is no clause';
  is scalar(@{ $fk{k42a_nulled} }), 3, 'a second target over the same column is a constraint of its own';
  is scalar(keys %{{ map { $_->[0] => 1 } @{ $fk{k42a_nulled} } }}), 3,
    '... with a name of its own (ORA-02264 otherwise)';
  cmp_ok length($_->[0]), '<=', 30, "constraint name $_->[0] fits 30 characters"
    for map { @$_ } values %fk;

  my $e = eval { DBIO::Oracle::DDL->install_ddl('T::K42B'); 1 } ? '' : "$@";
  like $e, qr/on_update 'CASCADE'.*no Oracle counterpart/s,
    'an on_update other than NO ACTION / RESTRICT is refused with an exception, not left out';
  $e = eval { DBIO::Oracle::DDL->install_ddl('T::K42C'); 1 } ? '' : "$@";
  like $e, qr/on_delete 'SET DEFAULT'.*no Oracle counterpart/s,
    'an on_delete Oracle does not have is refused too';
}

done_testing;
