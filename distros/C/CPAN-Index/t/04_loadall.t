#!/usr/bin/perl -w

# Test that CPAN::Index::Loader works

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use File::Remove        'remove';
use File::Copy          'copy';
use IO::File            ();
use CPAN::Index         ();
use CPAN::Index::Loader ();

# Locate the root path for the fake mirror
my $MIRROR = catdir('t', 'mirror');
ok( -d $MIRROR, "Found mirror dir at $MIRROR" );





#####################################################################
# Setting Up

# Set up the test database
my $TESTDB = catfile('share', 'cpan.db');
my $MYDB   = catfile('t',     'cpan.db');
my $MYDSN  = "dbi:SQLite:$MYDB";
      remove($MYDB) if -f $MYDB;
END { remove($MYDB) if -f $MYDB; }
ok( -f $TESTDB, 'Found empty database' );
ok( ! -f $MYDB, 'Testing copy does not exist yet' );
ok( copy( $TESTDB => $MYDB ), 'Create testing database' );
ok( -f $MYDB,   'Testing copy created ok' );

# Connect to the database
my $schema = CPAN::Index->connect( $MYDSN );
isa_ok( $schema, 'CPAN::Index', 'DBIx::Class::Schema' );





#####################################################################
# Loading the Database

# Load all the files
SCOPE: {
	my $loader = CPAN::Index::Loader->new(
		remote_uri => 'ftp://ftp.cpan.org/',
		local_dir  => $MIRROR,
		);
	isa_ok( $loader, 'CPAN::Index::Loader' );

	# Load the index
	my $records = $loader->load_index( $schema );
	is( $records, 18, '->load_index added the extected records' );
}

exit(0);
