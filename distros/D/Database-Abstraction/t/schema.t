#!perl -w

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most tests => 21;
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

# Cached calls return the same ref
is($t1->columns(), $cols,   'columns() is cached');
is($t1->schema(),  $schema, 'schema() is cached');

# ---- SQLite DBI path ----

SKIP: {
	eval { require DBI; require DBD::SQLite };
	skip 'DBD::SQLite not available', 7 if $@;

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
}
