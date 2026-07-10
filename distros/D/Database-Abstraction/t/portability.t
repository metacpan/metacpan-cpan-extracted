#!perl -w

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Test::NoWarnings;

# Use SQLite via DSN to avoid needing Postgres/MySQL in CI.
# This exercises the dsn constructor path, dialect detection,
# SQLite PRAGMA setup, and schema introspection over a DSN connection.

eval { require DBI; require DBD::SQLite };
if ($@) {
	plan skip_all => 'DBD::SQLite not available';
} else {
	plan tests => 16;
}

{
	package Database::porttest;
	use base 'Database::Abstraction';
}

my $dir  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, 'porttest.sql');
my $dsn  = "dbi:SQLite:dbname=$file";

# Create the schema and insert rows
my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
$setup->do(q{CREATE TABLE porttest (id INTEGER PRIMARY KEY, name TEXT NOT NULL, score REAL)});
$setup->do(q{INSERT INTO porttest VALUES (1, 'Alice', 9.5)});
$setup->do(q{INSERT INTO porttest VALUES (2, 'Bob',   7.0)});
$setup->disconnect();

# Connect via DSN — no directory needed
my $db = Database::porttest->new(dsn => $dsn, no_entry => 1);
isa_ok($db, 'Database::porttest', 'object created via dsn');

# Basic select (triggers _open)
my $rows = $db->selectall_arrayref();
is(scalar @{$rows}, 2, 'selectall_arrayref returns 2 rows');

# Check internals after _open has run
is($db->{'type'},     'DBI',    'type is DBI');
is($db->{'_dialect'}, 'sqlite', 'dialect detected as sqlite');
ok($db->{'_updated'}, 'updated() is set');

my $row = $db->fetchrow_hashref(id => 1);
is($row->{'name'}, 'Alice', 'fetchrow_hashref by id');

# count
is($db->count(), 2, 'count() without criteria');
is($db->count(name => 'Bob'), 1, 'count() with criteria');

# execute
my @all = $db->execute(query => 'SELECT * FROM porttest ORDER BY id');
is(scalar @all, 2, 'execute() in list context');
is($all[0]{'name'}, 'Alice', 'execute() first row');

# Schema introspection over DSN
my $cols = $db->columns();
isa_ok($cols, 'ARRAY', 'columns() over DSN returns arrayref');
ok((grep { $_ eq 'id'   } @{$cols}), 'columns() has "id"');
ok((grep { $_ eq 'name' } @{$cols}), 'columns() has "name"');

my $schema = $db->schema();
isa_ok($schema, 'HASH', 'schema() over DSN returns hashref');
is($schema->{'id'}{'pk'}, 1, 'pk column detected via DSN');
