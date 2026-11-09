use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';
}

use DBI ();
use DBIO::Core ();
use DBIO::Schema ();
use DBIO::Schema::ModelCompiler ();
use DBIO::SQLite::Adapter ();
use DBIO::SQLite::DDL ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();
use DBIO::SQLite::Diff::Column ();
use DBIO::SQLite::Introspect ();
use DBIO::SQLite::Util qw(split_type_size);

# karr k79, shared case ddl-type-size-passthrough. SQLite keeps a column's
# length and precision in the declared type text, CHARACTER(10). The
# introspected model reports it as the size of the column and the type
# without it, the way every other driver's model does, so the case can read
# the size back, and a regenerated result class says size => 10. The DDL
# writes the size for every type that has one, bit included.

# --- the one function that takes a declared type apart

is_deeply [ split_type_size('CHARACTER(10)') ],         [ 'CHARACTER', 10 ],
  'a length is the size';
is_deeply [ split_type_size('NUMERIC(10,2)') ],         [ 'NUMERIC', [ 10, 2 ] ],
  'precision and scale are a pair';
is_deeply [ split_type_size('decimal( 10 , 2 )') ],     [ 'decimal', [ 10, 2 ] ],
  'spaces inside the parentheses do not matter';
is_deeply [ split_type_size('UNSIGNED BIG INT(8)') ],   [ 'UNSIGNED BIG INT', 8 ],
  'a type of several words';
is_deeply [ split_type_size('TEXT') ],                  [ 'TEXT', undef ],
  'a type without parentheses has no size';
is_deeply [ split_type_size('VARCHAR(max)') ],          [ 'VARCHAR(max)', undef ],
  'what is not a number in parentheses stays in the type';
is_deeply [ split_type_size('') ],                      [ '', undef ],
  'the empty type';
is_deeply [ split_type_size(undef) ],                   [ undef, undef ],
  'no type';

# --- Introspect

sub dbh_with {
  my ($ddl) = @_;
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1, PrintError => 0 });
  $dbh->do($ddl);
  return $dbh;
}

{
  my $dbh = dbh_with('CREATE TABLE t (id INTEGER PRIMARY KEY, c CHARACTER(10), '
    . 'b BIT(8), n NUMERIC(10, 2), v VARCHAR(20), x TEXT, d DOUBLE PRECISION)');
  my $intro = DBIO::SQLite::Introspect->new(dbh => $dbh);
  my $info  = $intro->table_columns_info('t');

  is $info->{c}{data_type}, 'CHARACTER', 'CHARACTER(10): the type without the size';
  is $info->{c}{size}, 10,               'CHARACTER(10): size 10';
  is $info->{b}{data_type}, 'BIT',       'BIT(8): the type';
  is $info->{b}{size}, 8,                'BIT(8): size 8';
  is $info->{n}{data_type}, 'NUMERIC',   'NUMERIC(10, 2): the type';
  is_deeply $info->{n}{size}, [ 10, 2 ], 'NUMERIC(10, 2): precision and scale';
  is $info->{v}{size}, 20,               'VARCHAR(20): size 20';
  ok !exists $info->{x}{size},           'TEXT carries no size';
  is $info->{d}{data_type}, 'DOUBLE PRECISION', 'a type without a size is untouched';
  ok !exists $info->{d}{size},           'DOUBLE PRECISION carries no size';
  is $info->{id}{data_type}, 'INTEGER',  'the key column';
  ok $info->{id}{is_auto_increment},     'INTEGER PRIMARY KEY is still the rowid alias';
}

# --- the DDL writes the size, and the model stays quiet about it

{
  package Sz::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package Sz::Schema::Result::Sized;
  use base 'DBIO::Core';
  __PACKAGE__->table('sized');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    c    => { data_type => 'character', size => 10, is_nullable => 1 },
    b    => { data_type => 'bit', size => 8, is_nullable => 1 },
    n    => { data_type => 'decimal', size => [ 10, 2 ], is_nullable => 1 },
    v    => { data_type => 'varchar', size => 20, is_nullable => 1 },
    k    => { data_type => 'char', size => 5, is_nullable => 1 },
    big  => { data_type => 'bigint', size => 20, is_nullable => 1 },
    i    => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
Sz::Schema->register_class(Sized => 'Sz::Schema::Result::Sized');

my $ddl = DBIO::SQLite::DDL->install_ddl('Sz::Schema');
like $ddl, qr/"c" CHARACTER\(10\)/,   'character keeps its length';
like $ddl, qr/"b" BIT\(8\)/,          'bit keeps its size';
like $ddl, qr/"n" NUMERIC\(10,2\)/,   'decimal keeps precision and scale';
like $ddl, qr/"v" VARCHAR\(20\)/,     'varchar keeps its length';
like $ddl, qr/"k" CHAR\(5\)/,         'a base char keeps its length';
like $ddl, qr/"big" INTEGER[ ,]/,     'a type SQLite maps to INTEGER is written as before';

my $schema = Sz::Schema->connect('dbi:SQLite::memory:');
$schema->deploy;

my $info = DBIO::SQLite::Introspect->new(dbh => $schema->storage->dbh)
  ->table_columns_info('sized');
is $info->{c}{size}, 10, 'deployed character reads back with size 10';
is $info->{b}{size}, 8,  'deployed bit reads back with size 8';
is_deeply $info->{n}{size}, [ 10, 2 ], 'deployed decimal reads back as a pair';

ok !DBIO::SQLite::Deploy->new(schema => $schema)->diff->has_changes,
  'deploy, then diff against the same declaration, is empty';

# A database that was deployed before: the type text is the same, so the
# model on both sides is the same and an upgrade finds nothing to do, also
# for a spelling the DDL does not write.
{
  my $old = Sz::Schema->connect('dbi:SQLite::memory:');
  $old->storage->dbh->do('CREATE TABLE "sized" ("id" INTEGER PRIMARY KEY NOT NULL, '
    . '"c" CHARACTER(10), "b" BIT(8), "n" NUMERIC(10, 2), "v" VARCHAR(20), '
    . '"k" CHAR(5), "big" INTEGER, "i" INTEGER)');
  ok !DBIO::SQLite::Deploy->new(schema => $old)->diff->has_changes,
    'a database deployed earlier differs from the declaration in nothing';
}

# A size changed in the declaration is a change, as it was.
{
  my $old = Sz::Schema->connect('dbi:SQLite::memory:');
  $old->storage->dbh->do('CREATE TABLE "sized" ("id" INTEGER PRIMARY KEY NOT NULL, '
    . '"c" CHARACTER(9), "b" BIT(8), "n" NUMERIC(10,2), "v" VARCHAR(20), '
    . '"k" CHAR(5), "big" INTEGER, "i" INTEGER)');
  my $diff = DBIO::SQLite::Deploy->new(schema => $old)->diff;
  ok $diff->has_changes, 'CHARACTER(9) against CHARACTER(10) is a change';
}

# --- the compiled model splits the same way as the introspected one

{
  package Sz2::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package Sz2::Schema::Result::Base;
  use base 'DBIO::Core';
  __PACKAGE__->table('base');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    k  => { data_type => 'char', size => 5 },
    n  => { data_type => 'numeric', size => [ 10, 2 ] },
  );
  __PACKAGE__->set_primary_key('id');
}
Sz2::Schema->register_class(Base => 'Sz2::Schema::Result::Base');

{
  my $compiled = DBIO::Schema::ModelCompiler
    ->new(adapter => DBIO::SQLite::Adapter->new)->compile('Sz2::Schema');
  my $target = DBIO::SQLite::Diff->target_from_compiled($compiled);
  my %col = map { $_->{column_name} => $_ } @{ $target->{columns}{base} };
  is $col{k}{data_type}, 'CHAR', 'compiled CHAR(5): the type';
  is $col{k}{size}, 5,           'compiled CHAR(5): the size';
  is $col{n}{data_type}, 'NUMERIC', 'compiled NUMERIC(10,2): the type';
  is_deeply $col{n}{size}, [ 10, 2 ], 'compiled NUMERIC(10,2): the pair';

  my $live = Sz2::Schema->connect('dbi:SQLite::memory:');
  $live->deploy;
  my $source = DBIO::SQLite::Introspect->new(dbh => $live->storage->dbh)->model;
  ok !DBIO::SQLite::Diff->new(source => $source, target => $target)->has_changes,
    'the compiled target against a deployed database: no change';
}

# --- a column written from its fields keeps its size

{
  my $op = DBIO::SQLite::Diff::Column->new(
    action      => 'add',
    table_name  => 'sized',
    column_name => 'extra',
    new_info    => { data_type => 'VARCHAR', size => 20, not_null => 0 },
  );
  like $op->as_sql, qr/ADD COLUMN "extra" VARCHAR\(20\);/,
    'ADD COLUMN written from the fields carries the size';
  my $pair = DBIO::SQLite::Diff::Column->new(
    action      => 'add',
    table_name  => 'sized',
    column_name => 'extra',
    new_info    => { data_type => 'NUMERIC', size => [ 10, 2 ] },
  );
  like $pair->as_sql, qr/ADD COLUMN "extra" NUMERIC\(10,2\);/,
    'and so does a precision and scale';
}

# --- the declared deviation: SQLite does not enforce the length

{
  my $dbh = $schema->storage->dbh;
  $dbh->do(q{INSERT INTO "sized" ("id", "c") VALUES (1, ?)}, undef, 'x' x 11);
  my ($stored) = $dbh->selectrow_array('SELECT "c" FROM "sized" WHERE "id" = 1');
  is length($stored), 11,
    'a column of CHARACTER(10) stores 11 characters: SQLite does not enforce the length';
  unlike $ddl, qr/CHECK/i, 'and the DDL writes no CHECK to make it';
}

done_testing;
