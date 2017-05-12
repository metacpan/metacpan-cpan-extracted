#!/usr/bin/perl

# Tests for the various generators

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Flat;
use Archive::Builder;

# Create our Generator 
use vars qw{$Generator $Section1 $Section2};
sub init {
	$Generator = Archive::Builder->new();
	$Section1 = $Generator->new_section( 'one' );
	$Section1->new_file( 'one', 'string', 'filecontents' );
	my $string = 'trivial';
	$Section1->new_file( 'two', 'string', \$string );

	# Write the test file
	File::Flat->write( 'test.txt', 'test file' );
	$Section1->new_file( 'three', 'file', 'test.txt' );

	# Create a handle to test with
	my $handle = File::Flat->getReadHandle( 'test.txt' );
	$Section1->new_file( 'four', 'handle', $handle );
}
init();







# Prepare by saving the builder
my $rv = $Generator->save( 'first' );
ok( $rv, 'Builder using default generators returns true' );

#Test the file contents
my $files = {
	'./first/one/one'   => 'filecontents',
	'./first/one/two'   => 'trivial',
	'./first/one/three' => "test file",
	'./first/one/four'  => 'test file',
	};
foreach ( keys %$files ) {
	ok( File::Flat->exists( $_ ), "File '$_' exists" );
	file_contains( $_, $files->{$_} );
}
	



# Additional tests

sub file_contains {
	my $filename = shift;
	my $contains = shift;
	return ok( undef, "File $filename doesn't exist" ) unless -e $filename;
	return ok( undef, "$filename isn't a file" ) unless -f $filename;
	return ok( undef, "Can't read contents of $filename" ) unless -r $filename;
	my $contents = File::Flat->slurp( $filename )
		or return ok( undef, 'Error while slurping file' );
	return is( $$contents, $contains, "File $filename contents match expected value" );
}

END {
	File::Flat->remove( 'first' );
	File::Flat->remove( 'text.txt' );
}
