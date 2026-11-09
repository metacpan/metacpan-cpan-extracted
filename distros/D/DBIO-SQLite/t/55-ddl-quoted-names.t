use strict;
use warnings;
use Test::More;
use Test::Exception;

# Names that only exist quoted: with a space, in mixed case, with a double
# quote inside (karr k57). They install, read back exactly as declared, and
# survive an upgrade that rebuilds their tables -- the rebuild has to find the
# table's name in the stored statement, where a name with a double quote in it
# stands as "a""b", and has to name a temporary table after it.
#
# And the one name that is not quoted at all: a table name given as a scalar
# ref is literal SQL by the schema's own declaration and is written as given.

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBIO::SQLite::Deploy;
use DBIO::SQLite::DDL;
use DBIO::SQLite::Introspect;

sub model { DBIO::SQLite::Introspect->new(dbh => $_[0])->model }

# ---------------------------------------------------------------------------
# Two versions of one schema. In the second, one column of every table has
# become NOT NULL, which SQLite can only do by rebuilding the table.
# ---------------------------------------------------------------------------
for my $version ([ NamesV1 => 1 ], [ NamesV2 => 0 ]) {
  my ($ns, $nullable) = @$version;
  my $code = <<'PERL';
    package __NS__;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');

    package __NS__::Result::Spaced;
    use base 'DBIO::Core';
    __PACKAGE__->table('My Table');
    __PACKAGE__->add_columns(
      'id'         => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      'first name' => { data_type => 'varchar', size => 40, is_nullable => __NULLABLE__,
                        accessor => 'first_name' },
    );
    __PACKAGE__->set_primary_key('id');

    package __NS__::Result::Mixed;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('SQLite::Result');
    __PACKAGE__->table('MixedCase');
    __PACKAGE__->add_columns(
      'Id'          => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      'camelCol'    => { data_type => 'varchar', size => 40, is_nullable => __NULLABLE__ },
      'my table id' => { data_type => 'integer', is_nullable => 0, accessor => 'my_table_id' },
    );
    __PACKAGE__->set_primary_key('Id');
    __PACKAGE__->add_unique_constraint('Mixed Unique' => ['camelCol']);
    __PACKAGE__->belongs_to(spaced => '__NS__::Result::Spaced', 'my table id');
    __PACKAGE__->sqlite_index('Idx Mixed' => { columns => [ 'my table id', 'camelCol' ] });

    package __NS__::Result::Quoted;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('SQLite::Result');
    __PACKAGE__->table('a"b');
    __PACKAGE__->add_columns(
      'id'       => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      'c"d'      => { data_type => 'varchar', size => 40, is_nullable => __NULLABLE__,
                      accessor => 'c_d' },
      'say "hi"' => { data_type => 'integer', is_nullable => 1, accessor => 'say_hi' },
      'mixed'    => { data_type => 'integer', is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(mixed => '__NS__::Result::Mixed', 'mixed');
    __PACKAGE__->belongs_to(self => '__NS__::Result::Quoted', 'say "hi"');
    __PACKAGE__->sqlite_index('i"x' => { columns => ['c"d'] });

    __NS__->register_class(Spaced => '__NS__::Result::Spaced');
    __NS__->register_class(Mixed  => '__NS__::Result::Mixed');
    __NS__->register_class(Quoted => '__NS__::Result::Quoted');
    1;
PERL
  $code =~ s/__NS__/$ns/g;
  $code =~ s/__NULLABLE__/$nullable/g;
  eval $code or die $@;    ## no critic (ProhibitStringyEval)
}

my %COLUMNS = (
  'My Table'  => [ 'id', 'first name' ],
  'MixedCase' => [ 'Id', 'camelCol', 'my table id' ],
  'a"b'       => [ 'id', 'c"d', 'say "hi"', 'mixed' ],
);

# What the model has to say about the three tables, whichever way they came to
# be: by the install, or by the upgrade that rebuilt every one of them.
sub names_read_back {
  my ($dbh, $when) = @_;
  my $model = model($dbh);

  is_deeply([ sort keys %{ $model->{tables} } ], [ sort keys %COLUMNS ],
    "$when: the three tables read back by their names, exactly");

  for my $table (sort keys %COLUMNS) {
    is_deeply(
      [ map { $_->{column_name} } @{ $model->{columns}{$table} } ],
      $COLUMNS{$table},
      "$when: the columns of <$table>, exactly and in order",
    );
  }

  my $explicit = sub {
    my $indexes = $model->{indexes}{ $_[0] } // {};
    return { map { $_ => $indexes->{$_}{columns} }
      grep { ($indexes->{$_}{origin} // '') eq 'c' } keys %$indexes };
  };
  is_deeply($explicit->('MixedCase'), { 'Idx Mixed' => [ 'my table id', 'camelCol' ] },
    "$when: the index <Idx Mixed> with its columns");
  is_deeply($explicit->('a"b'), { 'i"x' => ['c"d'] },
    "$when: the index <i\"x> on <c\"d>");

  my ($unique) = grep { ($_->{origin} // '') eq 'u' }
    values %{ $model->{indexes}{MixedCase} };
  is_deeply($unique->{columns}, ['camelCol'], "$when: the unique constraint is over <camelCol>");

  my $keys = sub {
    return [ sort map {
      join ' ', "@{ $_->{from_columns} }", '->', $_->{to_table}, "@{ $_->{to_columns} }"
    } @{ $model->{foreign_keys}{ $_[0] } // [] } ];
  };
  is_deeply($keys->('MixedCase'), ['my table id -> My Table id'],
    "$when: the foreign key of <MixedCase>");
  is_deeply($keys->('a"b'), [ 'mixed -> MixedCase Id', 'say "hi" -> a"b id' ],
    "$when: the foreign keys of <a\"b>, one of them to itself");

  return $model;
}

{
  my $schema = NamesV1->connect('dbi:SQLite::memory:', '', '', {
    AutoCommit => 1, on_connect_call => 'use_foreign_keys',
  });
  my $dbh = $schema->storage->dbh;

  lives_ok { DBIO::SQLite::Deploy->new(schema => $schema)->install }
    'names with a space, in mixed case and with a double quote install'
    or diag(DBIO::SQLite::DDL->install_ddl($schema));

  my $model = names_read_back($dbh, 'installed');

  like($model->{tables}{'a"b'}{sql}, qr/\ACREATE TABLE "a""b" \(/,
    'the stored statement has the double quote of the name doubled');

  my $settled = DBIO::SQLite::Deploy->new(schema => $schema)->diff;
  ok(!$settled->has_changes, 'a diff against the schema it was installed from is empty')
    or diag($settled->summary);

  $dbh->do(q{INSERT INTO "My Table" ("id", "first name") VALUES (1, 'Ada')});
  $dbh->do(q{INSERT INTO "MixedCase" ("Id", "camelCol", "my table id") VALUES (1, 'x', 1)});
  $dbh->do(q{INSERT INTO "a""b" ("id", "c""d", "say ""hi""", "mixed") VALUES (1, 'q', 1, 1)});
  $dbh->do(q{INSERT INTO "a""b" ("id", "c""d", "say ""hi""", "mixed") VALUES (2, 'r', 1, NULL)});

  # SQLite does not fold a name: the quoted name and the bare one, in any
  # letter case, are one table. Quoting every name changed no meaning.
  is_deeply($dbh->selectall_arrayref('SELECT camelcol FROM mixedcase'), [ ['x'] ],
    'the quoted <MixedCase> is the table a bare, lower-case name finds');

  # -------------------------------------------------------------------------
  # The upgrade: every table rebuilt.
  # -------------------------------------------------------------------------
  my $v2      = NamesV2->connect(sub { $dbh });
  my $upgrade = DBIO::SQLite::Deploy->new(schema => $v2);
  my $diff    = $upgrade->diff;

  is_deeply(
    [ sort map { $_->table_name } grep { $_->isa('DBIO::SQLite::Diff::Rebuild') } @{ $diff->operations } ],
    [ sort keys %COLUMNS ],
    'the upgrade rebuilds the three tables',
  );

  my $sql = $diff->as_sql;
  like($sql, qr/^CREATE TABLE "a""b__dbio_rebuild" \($/m,
    'the temporary table of <a"b>: the name found in the statement and replaced');
  like($sql, qr/^ALTER TABLE "a""b__dbio_rebuild" RENAME TO "a""b";$/m,
    'and renamed into place');
  like($sql, qr/^INSERT INTO "My Table__dbio_rebuild" \("id", "first name"\)$/m,
    'the copy list of <My Table> is quoted');

  lives_ok { $upgrade->apply($diff) } 'the upgrade applies' or diag($sql);

  names_read_back($dbh, 'rebuilt');

  is_deeply(
    $dbh->selectall_arrayref(q{SELECT "id", "first name" FROM "My Table"}),
    [ [ 1, 'Ada' ] ],
    'the row of <My Table> survived',
  );
  is_deeply(
    $dbh->selectall_arrayref(q{SELECT "Id", "camelCol", "my table id" FROM "MixedCase"}),
    [ [ 1, 'x', 1 ] ],
    'the row of <MixedCase> survived',
  );
  is_deeply(
    $dbh->selectall_arrayref(
      q{SELECT "id", "c""d", "say ""hi""", "mixed" FROM "a""b" ORDER BY "id"}),
    [ [ 1, 'q', 1, 1 ], [ 2, 'r', 1, undef ] ],
    'the rows of <a"b> survived',
  );

  throws_ok { $dbh->do(q{INSERT INTO "a""b" ("id") VALUES (3)}) }
    qr/NOT NULL constraint failed: a"b\.c"d/, 'the new NOT NULL is in force';
  throws_ok { $dbh->do(q{INSERT INTO "a""b" ("c""d", "mixed") VALUES ('s', 99)}) }
    qr/FOREIGN KEY constraint failed/, 'and so are the foreign keys of the rebuilt tables';

  my $again = $upgrade->diff;
  ok(!$again->has_changes, 'a second diff is empty') or diag($again->summary);
}

# ---------------------------------------------------------------------------
# A table name given as a scalar ref is written as given -- in its CREATE
# TABLE, as the table of its index and as a foreign key's target. Quoted, a
# literal name would be another name: "main.lit_schema" is a table with a dot
# in its name and not the table lit_schema of the schema main, and a literal
# that brings its own quotes would get them twice.
# ---------------------------------------------------------------------------
{
  package LiteralName;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package LiteralName::Result::Plain;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('SQLite::Result');
  __PACKAGE__->table(\'lit_plain');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    peer => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(peer => 'LiteralName::Result::Plain', 'peer');
  __PACKAGE__->sqlite_index(idx_lit_peer => { columns => ['peer'] });
}
{
  package LiteralName::Result::OwnQuotes;
  use base 'DBIO::Core';
  __PACKAGE__->table(\'"LitQuoted"');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package LiteralName::Result::Qualified;
  use base 'DBIO::Core';
  __PACKAGE__->table(\'main.lit_schema');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package LiteralName::Result::Child;
  use base 'DBIO::Core';
  __PACKAGE__->table('lit_child');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    plain  => { data_type => 'integer', is_nullable => 0 },
    quoted => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(plain  => 'LiteralName::Result::Plain',     'plain');
  __PACKAGE__->belongs_to(quoted => 'LiteralName::Result::OwnQuotes', 'quoted');
}
LiteralName->register_class(Plain     => 'LiteralName::Result::Plain');
LiteralName->register_class(OwnQuotes => 'LiteralName::Result::OwnQuotes');
LiteralName->register_class(Qualified => 'LiteralName::Result::Qualified');
LiteralName->register_class(Child     => 'LiteralName::Result::Child');

{
  my $ddl = DBIO::SQLite::DDL->install_ddl('LiteralName');

  like($ddl, qr/^CREATE TABLE lit_plain \($/m, 'a literal name is written as given');
  like($ddl, qr/^CREATE TABLE "LitQuoted" \($/m,
    'one that brings its own quotes keeps them, once');
  like($ddl, qr/^CREATE TABLE main\.lit_schema \($/m,
    'one with a schema prefix is not turned into one quoted name');
  like($ddl, qr/^  FOREIGN KEY \("peer"\) REFERENCES lit_plain\("id"\)$/m,
    'a foreign key names a literal target as given -- the columns are names, and quoted');
  like($ddl, qr/^  FOREIGN KEY \("quoted"\) REFERENCES "LitQuoted"\("id"\)$/m,
    'also one with its own quotes');
  like($ddl, qr/^CREATE INDEX "idx_lit_peer" ON lit_plain \("peer"\);$/m,
    'an index names its literal table as given');
  like($ddl, qr/^CREATE TABLE "lit_child" \($/m, 'a plain name beside them is quoted');

  my $schema = LiteralName->connect('dbi:SQLite::memory:', '', '', {
    AutoCommit => 1, on_connect_call => 'use_foreign_keys',
  });
  my $dbh = $schema->storage->dbh;
  lives_ok { DBIO::SQLite::Deploy->new(schema => $schema)->install }
    'the schema with literal table names installs' or diag($ddl);

  is_deeply(
    [ sort keys %{ model($dbh)->{tables} } ],
    [qw(LitQuoted lit_child lit_plain lit_schema)],
    'and the database has the tables the literals name',
  );

  my $plain = $schema->resultset('Plain')->create({});
  my $own   = $schema->resultset('OwnQuotes')->create({});
  ok($schema->resultset('Qualified')->create({})->id,
    'the ORM, which writes the same literal, finds the table with the schema prefix');
  ok($schema->resultset('Child')->create({ plain => $plain->id, quoted => $own->id })->id,
    'and a row pointing at two literal-named tables goes in');

  my $settled = DBIO::SQLite::Deploy->new(schema => $schema)->diff;
  ok(!$settled->has_changes, 'a diff against the schema it was installed from is empty')
    or diag($settled->summary);
}

done_testing;
