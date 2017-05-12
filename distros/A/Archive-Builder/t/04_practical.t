#!/usr/bin/perl

# Contains more practical tests for Archive::Builder

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 36;
use File::Flat;
use Archive::Builder;

# Create our Generator 
use vars qw{$Generator $Section1 $Section2};
sub init {
	$Generator = Archive::Builder->new();
	$Section1 = $Generator->new_section( 'one' );
	$Section1->new_file( 'this', 'main::trivial' );
	$Section1->new_file( 'that', 'main::direct', 'filecontents' );
	$Section1->new_file( 'foo/bar', 'main::direct', "Contains\ntwo lines" );
	$Section1->new_file( 'x/is a/number.file', 'main::numbers' );
	$Section2 = $Generator->new_section( 'two' );
	$Section2->new_file( 'another/file', 'main::trivial' );
	$Section2->new_file( 'another/ortwo', 'main::direct', 'filecontents' );
}
init();





########################################################################
# Check the Archive::Builder ->files method
{
	my $files = $Generator->files;
	ok( ref $files eq 'HASH', '->files returns a HASH ref' );
	is( scalar(keys %$files), 6, '->files returns 6 files' );
	foreach ( qw{
		one/this
		one/that
		one/foo/bar
		two/another/file
		two/another/ortwo
		},
		'one/x/is a/number.file',
	) {
		ok( defined $files->{$_}, "Key '$_' exists" );
		isa_ok( $files->{$_}, 'Archive::Builder::File' );
	}
}





########################################################################
# Save tests

# Adding additional file_count test in
is( $Generator->file_count, 6, '->file_count is correct' );

# Try to save a single file
my $rv = $Generator->section( 'one' )->file( 'this' )->save( './first/file.txt' );
ok( $rv, 'File ->save returns true' );
ok( File::Flat->exists( './first/file.txt' ), 'File ->save creates file' );
file_contains( './first/file.txt', 'trivial' );

# Save a section
$rv = $Generator->section( 'two' )->save( './second' );
ok( $rv, 'Section ->save returns true' );
ok( File::Flat->exists( './second/another/file' ), 'First file exists' );
ok( File::Flat->exists( './second/another/ortwo' ), 'Second file exists' );
file_contains( './second/another/file', 'trivial' );
file_contains( './second/another/ortwo', 'filecontents' );

# Save the entire Archive::Builder
$rv = $Generator->save( './third' );
ok( $rv, 'Archive::Builder ->save returns true' );
my $files = {
	'./third/one/this'               => 'trivial',
	'./third/one/that'               => 'filecontents',
	'./third/one/foo/bar'            => "Contains\ntwo lines",
	'./third/one/x/is a/number.file' => "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n",
	'./third/two/another/file'       => 'trivial',
	'./third/two/another/ortwo'      => 'filecontents',
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
	is( $$contents, $contains, "File $filename contents match expected value" );
}





# Archive::Builders
sub trivial {
	my $File = shift;
	my $value = 'trivial';
	\$value;
}

sub direct {
	my $File = shift;
	my $contents = shift;
	\$contents;
}

sub numbers {
	my $File = shift;
	my $string = join '', map { "$_\n" } 1 .. 10;
	\$string;
}




END {
	File::Flat->remove('first');
	File::Flat->remove('second');
	File::Flat->remove('third');
}
