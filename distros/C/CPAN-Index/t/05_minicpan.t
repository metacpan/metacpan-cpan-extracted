#!/usr/bin/perl -w

# Test that CPAN::Index::Loader works

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Remove        'remove';
use File::Copy          'copy';
use IO::File            ();
use CPAN::Index         ();
use CPAN::Index::Loader ();

# Locate the root path for the fake mirror
my $MIRROR = $ENV{MINICPAN};
#unless ( $ENV{AUTOMATED_TESTING} ) {
#	plan( skip_all => 'Too heavy for normal installation' );
#}
unless ( $MIRROR ) {
	plan( skip_all => 'No local minicpan detected' );
}

# We are going ahead with the minicpan test
plan( tests => 6 );





#####################################################################
# Setting Up

# Set up the test database
my $TESTDB = catfile('share', 'cpan.db');
my $MYDB   = catfile('t',     'cpan.db');
my $MYDSN  = "dbi:SQLite:$MYDB";
      remove($MYDB) if -f $MYDB;
END { remove($MYDB) if $MYDB and -f $MYDB; }
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
	diag("This may take some time...");
	my $records = $loader->load_index( $schema );
	is( $records, 18, '->load_index added the extected records' );
}

exit(0);
