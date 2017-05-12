#!/usr/bin/perl -w

# Test that CPAN::Index::Loader works

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 25;
use File::Remove        'remove';
use File::Copy          'copy';
use IO::File            ();
use CPAN::Index         ();
use CPAN::Index::Loader ();

# Locate and open a handle to the plain test author file
my $AUTHOR = catfile('t', 'mirror', 'authors', '01mailrc.txt');
ok( -f $AUTHOR, "Found uncompressed author file at $AUTHOR" );

# Locate and open a handle to the plain test package file
my $PACKAGE = catfile('t', 'mirror', 'modules', '02packages.details.txt');
ok( -f $PACKAGE, "Found uncompressed package file at $PACKAGE" );





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

# Load the authors
SCOPE: {
	my $authors = IO::File->new( $AUTHOR );
	isa_ok( $authors, 'IO::File', 'IO::Handle' );
	my $added = CPAN::Index::Loader->load_authors( $schema, $authors );
	is( $added, 9, 'Appeared to add 9 authors' );
	is( $schema->resultset('Author')->count, 9, 'Actually added 9 records' );
	my $aassad = $schema->resultset('Author')->find('AASSAD');
	isa_ok( $aassad, 'CPAN::Index::Author' );
	is( $aassad->id, 'AASSAD', '->id ok' );
	is( $aassad->name, "Arnaud 'Arhuman' Assad", '->name ok' );
	is( $aassad->email, 'arhuman@hotmail.com', '->email ok' );
	isa_ok( $aassad->address, 'Email::Address' );

	# Check we used the entire handle
	ok( $authors->eof, 'Handle at EOF after loading' );
}

# Load the packages
SCOPE: {
	my $packages = IO::File->new( $PACKAGE );
	isa_ok( $packages, 'IO::File', 'IO::Handle' );
	my $added = CPAN::Index::Loader->load_packages( $schema, $packages );
	is( $added, 9, 'Appeared to add 9 packages' );
	is( $schema->resultset('Package')->count, 9, 'Actually added 9 records' );
	my $colour = $schema->resultset('Package')->find('Acme::Colour');
	isa_ok( $colour, 'CPAN::Index::Package' );
	is( $colour->name, 'Acme::Colour', '->name ok' );
	isa_ok( $colour->version, 'version' );
	is( $colour->version_string, '1.00', '->version ok' );
	is( $colour->path, 'L/LB/LBROCARD/Acme-Colour-1.00.tar.gz', '->path ok' );

	# Check we used the entire handle
	ok( $packages->eof, 'Handle at EOF after loading' );
}

exit(0);
