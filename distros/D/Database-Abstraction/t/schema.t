#!perl -w

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most tests => 26;
use Test::NoWarnings;

use lib 't/lib';
use Database::test1;
use FindBin qw($Bin);

# ---- CSV slurp path ----

pass('Database::test1 loaded');
my $data_dir = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $t1 = new_ok('Database::test1' => [$data_dir]);

my $cols = $t1->columns();
isa_ok($cols, 'ARRAY', 'columns() returns an arrayref');
ok(scalar(@{$cols}) > 0, 'columns() is non-empty');
ok((grep { $_ eq 'entry'  } @{$cols}), 'columns() includes "entry"');
ok((grep { $_ eq 'number' } @{$cols}), 'columns() includes "number"');

my $schema = $t1->schema();
isa_ok($schema, 'HASH', 'schema() returns a hashref');
ok(exists $schema->{'entry'},  'schema() has "entry" key');
ok(exists $schema->{'number'}, 'schema() has "number" key');
is($schema->{'entry'}{'pk'}, 1, '"entry" column is marked as pk');
is($schema->{'entry'}{'nullable'}, 0, '"entry" is not nullable');

# Ordering contract: columns() always returns alphabetically sorted names
is_deeply($cols, [sort @{$cols}], 'slurp columns() is alphabetically sorted');

# Cached calls return the same ref
is($t1->columns(), $cols,   'columns() is cached');
is($t1->schema(),  $schema, 'schema() is cached');

# ---- SQLite DBI path ----

SKIP: {
	eval { require DBI; require DBD::SQLite };
	skip 'DBD::SQLite not available', 8 if $@;

	my $dir = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($dir, 'schematest.sql');

	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", undef, undef, { RaiseError => 1 });
	$dbh->do(q{CREATE TABLE schematest (id INTEGER PRIMARY KEY, name TEXT NOT NULL, score REAL)});
	$dbh->disconnect();

	{
		package Database::schematest;
		use base 'Database::Abstraction';
	}

	my $obj = Database::schematest->new(directory => $dir, no_entry => 1);
	isa_ok($obj, 'Database::schematest');

	my $sql_cols = $obj->columns();
	isa_ok($sql_cols, 'ARRAY', 'SQLite columns() returns arrayref');
	ok((grep { $_ eq 'id'    } @{$sql_cols}), 'SQLite schema has "id"');
	ok((grep { $_ eq 'name'  } @{$sql_cols}), 'SQLite schema has "name"');
	ok((grep { $_ eq 'score' } @{$sql_cols}), 'SQLite schema has "score"');

	my $sql_schema = $obj->schema();
	isa_ok($sql_schema, 'HASH', 'SQLite schema() returns hashref');
	is($sql_schema->{'id'}{'pk'}, 1, 'SQLite pk column detected correctly');
	is_deeply($sql_cols, [sort @{$sql_cols}], 'SQLite columns() is alphabetically sorted');
}

# ---- columns() ordering: SQLite table declared in non-alphabetical order ----
# This verifies the fix: the DBI path now sorts $sth->{NAME} so that
# declaration order (score, id, name) becomes alphabetical (id, name, score).

SKIP: {
	eval { require DBI; require DBD::SQLite };
	skip 'DBD::SQLite not available', 3 if $@;

	my $dir2 = tempdir(CLEANUP => 1);
	my $dbfile2 = File::Spec->catfile($dir2, 'colorder.sql');
	my $dbh2 = DBI->connect("dbi:SQLite:dbname=$dbfile2", undef, undef, { RaiseError => 1 });
	$dbh2->do(q{CREATE TABLE colorder (score REAL, id INTEGER PRIMARY KEY, name TEXT)});
	$dbh2->disconnect();

	{
		package Database::colorder;
		use base 'Database::Abstraction';
	}

	my $ord = Database::colorder->new(directory => $dir2, no_entry => 1);
	isa_ok($ord, 'Database::colorder', 'colorder object created');

	my $ord_cols = $ord->columns();
	is_deeply($ord_cols, ['id', 'name', 'score'],
		'SQLite columns() sorted alphabetically despite reverse declaration order');
	is_deeply($ord_cols, [sort @{$ord_cols}],
		'SQLite out-of-order columns() passes sort invariant');
}
