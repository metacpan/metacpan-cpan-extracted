#!/usr/bin/perl -w

# Main testing script for Data::Package::SQLite

# Because the entire point of this module is to be relatively
# magic, it should be relatively safe to start by testing the
# most DWIM usage, and work our way towards the fine testing.

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			);
	}
}

use DBI;
use File::Path qw{mkpath rmtree};
use Test::More tests => 112;

# Add the t/lib in both harness and non-harness cases
use lib catdir('t', 'lib');

# Load the test packages
use My::DataPackage1 ();
use My::DataPackage2 ();
use My::DataPackage3 ();

# Create the test database
sub create_db {
	my ($dbfile, $type) = @_;
	ok( ! -f $dbfile, "Test database does not exist" );
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
	isa_ok( $dbh, 'DBI::db' );
	ok(
		$dbh->do("create table foo ( id int not null, string varchar(32) null )"),
		'Created test table',
	);
	ok(
		$dbh->do("insert into foo values ( 1, 'A test' )"),
		'Created test record 1',
	);
	ok(
		$dbh->do("insert into foo values ( 3, 'Another test' )"),
		'Created test record 2',
	);
	dbh_ok( $dbh, $type );
}

# Connection-testing function
sub dbh_ok {
	my ($dbh, $type) = @_;
	isa_ok( $dbh, 'DBI::db' );
	my $data = $dbh->selectall_arrayref('select * from foo');
	is( ref($data), 'ARRAY', "$type: ->fetchall_arrayref returns an ARRAY" );
	is( scalar(@$data), 2, "$type: ->fetchall_arrayref returns 2 rows" );
	is( ref($data->[0]), 'ARRAY', "$type: ->fetchall_arrayref returns an AoA" );
	is( scalar(@{$data->[0]}), 2, "$type: ->fetchall_arrayref returns AoA(2x2)" );
	is( scalar(@{$data->[1]}), 2, "$type: ->fetchall_arrayref returns AoA(2x2)" );
	is( $data->[0]->[0], 1, "$type: AoA(1,1) is 1" );
	is( $data->[0]->[1], 'A test', "$type: AoA(1,2) is correct string" );
	is( $data->[1]->[0], 3, "$type: AoA(2,1) is 1" );
	is( $data->[1]->[1], 'Another test', "$type: AoA(2,2) is correct string" );
	ok( $dbh->disconnect, "$type: ->disconnect OK" );
}





#####################################################################
# Preparation

# Clear any old test databases
my $test_root = catdir('t','lib','auto');
      if ( -d $test_root ) { rmtree($test_root, 0, 0) }
END { if ( -d $test_root ) { rmtree($test_root, 0, 0) } }
ok( ! -e $test_root, 'Test directory root does not exist' );

# Create the package 1 dir and create the DB
my $test_dir1 = catdir( $test_root, 'My', 'DataPackage1' );
my $test_db1  = catdir( $test_dir1, 'data.sqlite' );
ok( scalar(mkpath( $test_dir1, 0, 0711 )), 'Created test directory 1' );
ok( -d $test_dir1, 'Confirm created test directory 1' );
create_db( $test_db1, 'Test database 1' );
ok( -f $test_db1, 'Confirm created test db 1' );

# Create the package 2 dir and create the DB
my $test_dir2 = catdir( $test_root, 'My', 'DataPackage2' );
my $test_db2  = catdir( $test_dir2, 'data2.sqlite' );
ok( scalar(mkpath( $test_dir2, 0, 0711 )), 'Created test directory 2' );
ok( -d $test_dir2, 'Confirm created test directory 2' );
create_db( $test_db2, 'Test database 2' );
ok( -f $test_db2, 'Confirm created test db 2' );

# Create the package 3 dir and create the DB
my $test_dir3 = catdir( $test_root, 'My', 'DataPackage3' );
my $test_db3  = catdir( $test_dir3, 'data3.sqlite' );
ok( scalar(mkpath( $test_dir3, 0, 0711 )), 'Created test directory 3' );
ok( -d $test_dir3, 'Confirm created test directory 3' );
create_db( $test_db3, 'Test database 3' );
ok( -f $test_db3, 'Confirm created test db 3' );





#####################################################################
# Testing the sqlite_ methods

# Testing sqlite_location
is_deeply(
	[ My::DataPackage1->sqlite_location ],
	[ 'module_file', 'My::DataPackage1' ],
	'1: ->sqlite_location returns as expected',
);
is_deeply(
	[ My::DataPackage2->sqlite_location ],
	[ 'module_file', 'My::DataPackage2', 'data2.sqlite' ],
	'2: ->sqlite_location returns as expected',
);
is_deeply(
	[ My::DataPackage3->sqlite_location ],
	[ 'dist_file', 'My-DataPackage3', 'data3.sqlite' ],
	'3: ->sqlite_location returns as expected',
);

# Testing sqlite_file
is(
	My::DataPackage1->sqlite_file,
	't/lib/auto/My/DataPackage1/data.sqlite',
	'1: ->sqlite_file return as expected',
);
is(
	My::DataPackage2->sqlite_file,
	't/lib/auto/My/DataPackage2/data2.sqlite',
	'2: ->sqlite_file return as expected',
);
is(
	My::DataPackage3->sqlite_file,
	't/lib/auto/My/DataPackage3/data3.sqlite',
	'3: ->sqlite_file return as expected',
);

# Testing sqlite_dsn
is(
	My::DataPackage1->sqlite_dsn,
	'dbi:SQLite:dbname=t/lib/auto/My/DataPackage1/data.sqlite',
	'1: ->sqlite_dsn return as expected',
);
is(
	My::DataPackage2->sqlite_dsn,
	'dbi:SQLite:dbname=t/lib/auto/My/DataPackage2/data2.sqlite',
	'2: ->sqlite_dsn return as expected',
);
is(
	My::DataPackage3->sqlite_dsn,
	'dbi:SQLite:dbname=t/lib/auto/My/DataPackage3/data3.sqlite',
	'3: ->sqlite_dsn return as expected',
);





#####################################################################
# Main testing

# The most DWIM test
SCOPE: {
	my $dbh = My::DataPackage1->get;
	dbh_ok( $dbh, '1: DWIM ->get' );
}

# With explicit filename
SCOPE: {
	my $dbh = My::DataPackage1->get('DBI::db');
	dbh_ok( $dbh, "1: ->get('DBI::db')" );
}

# With wrong explicit filename
SCOPE: {
	my $rv = My::DataPackage1->get('Foo::Bar');
	is( $rv, undef, '1: ->get(bad) returns undef' );
}

# The most DWIM test for package 2
SCOPE: {
	my $dbh = My::DataPackage2->get;
	dbh_ok( $dbh, '2: DWIM ->get' );
}

# An alternative using dist_file
SCOPE: {
	my $dbh = My::DataPackage3->get;
	dbh_ok( $dbh, '3: DWIM ->get' );
}

exit(0);
