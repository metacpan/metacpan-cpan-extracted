#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use File::Spec::Functions ':ALL';

my $test_file  = rel2abs( catfile( 't', 'data', 'foo.txt' ) );
ok( -f $test_file, 'Test file exists' );
my $share_file = 'test.txt';





#####################################################################
# Main Tests

# Get the some files
ok( My::Test1->file, 'Got ->file for My::Test1' );
ok( My::Test2->file, 'Got ->file for My::Test2' );
ok( My::Test3->file, 'Got ->file for My::Test3' );

# Get them as IO objects
isa_ok( My::Test1->get('IO::File'), 'IO::File' );
isa_ok( My::Test2->get('IO::File'), 'IO::File' );
isa_ok( My::Test3->get('IO::File'), 'IO::File' );

# Get them as Path::Class objects
SKIP: {
	skip("Path::Class not available", 3) unless Class::Inspector->installed('Path::Class');
	isa_ok( My::Test1->get('Path::Class::File'), 'Path::Class::File' );
	isa_ok( My::Test2->get('Path::Class::File'), 'Path::Class::File' );
	isa_ok( My::Test3->get('Path::Class::File'), 'Path::Class::File' );	
}

# Get them as URI::file objects
SKIP: {
	skip("URI::file not available", 3) unless Class::Inspector->installed('URI::file');
	isa_ok( My::Test1->get('URI::file'), 'URI::file' );
	isa_ok( My::Test2->get('URI::file'), 'URI::file' );
	isa_ok( My::Test3->get('URI::file'), 'URI::file' );	
}





#####################################################################
# Test Packages

SCOPE: {
	package My::Test1;

	use Data::Package::File ();
	BEGIN {
		@My::Test1::ISA = 'Data::Package::File';
	}

	sub file {
		return File::Spec->rel2abs(
			File::Spec->catfile( 't', 'data', 'foo.txt' ),
		);
	}

	package My::Test2;

	use Data::Package::File ();
	BEGIN {
		@My::Test2::ISA = 'Data::Package::File';
	}

	sub dist_file {
		'Data-Package', 'test.txt';
	}

	package My::Test3;

	use Data::Package::File ();
	BEGIN {
		@My::Test3::ISA = 'Data::Package::File';
	}

	sub module_file {
		'Data::Package', 'test.txt';
	}
}
