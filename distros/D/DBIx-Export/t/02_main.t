#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use DBIx::Export          ();

# Locate the CVS database
my $input  = catfile('t', 'input.sqlite' );
my $output = catfile('t', 'output.sqlite');
File::Remove::clear($input);
File::Remove::clear($output);

# Connect to the source database
my $source = DBI->connect("DBI:SQLite:$input", {
	AutoCommit => 1,
	PrintError => 1,
	RaiseError => 1,
} );
isa_ok( $source, 'DBI::db' );
$source->do(<<'END_SQL');
CREATE TABLE table1 (
	id INTEGER NOT NULL PRIMARY KEY,
	foo CHAR(1) NOT NULL,
	bar VARCHAR(10) NOT NULL
)
END_SQL
$source->do(
	'insert into table1 values ( ?, ?, ? )', {},
	1, 'a', 'one',
);
$source->do(
	'insert into table1 values ( ?, ?, ? )', {},
	2, 'b', 'two',
);
$source->do(
	'insert into table1 values ( ?, ?, ? )', {},
	3, 'c', 'three',
);
$source->do(
	'insert into table1 values ( ?, ?, ? )', {},
	4, 'd', 'four',
);

# Create the export object
my $export = DBIx::Export->new(
	file   => $output,
	source => $source,
);
isa_ok( $export, 'DBIx::Export' );
is( $export->file, $output, '->file ok' );
ok( $export->source, '->source ok' );
isa_ok( $export->dbh, 'DBI::db', '->sqlite ok' );

# Fill some basic tables
ok(
	$export->table( 'simple1', 'select id, foo from table1 where id < ?', 4 ),
	'Created simple1 table',
);
ok(
	$export->table( 'simple2', 'select id, bar from table1 where id > ?', 1 ),
	'Created simple2 table',
);

# Clean up
ok( $export->finish, '->finish ok' );

1;
