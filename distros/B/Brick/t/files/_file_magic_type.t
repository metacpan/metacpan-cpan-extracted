#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use File::Spec;

use_ok( 'Brick' );
use_ok( 'Brick::Bucket' );
use_ok( 'Brick::Files' );

ok( defined &Brick::Bucket::_file_magic_type, "_file_magic_type sub is there");

my $bucket = 'Brick::Bucket';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These things should work, even if they have the wrong extension
{
my %files = qw(
	excel.xls	application/vnd.ms-excel
	word.doc 	application/x-msword
	word	 	application/x-msword
	text.txt	text/plain
	text		text/plain
	text.xls	text/plain
	);

foreach my $file ( sort keys %files )
	{
	my $path = File::Spec->catfile( qw( t files files_to_test ), $file );
	ok( -e $path, "File $file exists" );

	my $mime_type = $bucket->_file_magic_type( $path );
	is( $mime_type, $files{$file}, "Magic type for $file is right" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These things should work but don't

my %files = qw(
	excel		application/vnd.ms-excel
	excel.txt 	application/vnd.ms-excel
	);

foreach my $file ( sort keys %files )
	{
	my $path = File::Spec->catfile( qw( t files files_to_test ), $file );
	ok( -e $path, "File $file exists" );

	TODO: {
	local $TODO = "File::MMagic has trouble testing some excel files";
		my $mime_type = $bucket->_file_magic_type( $path );
		is( $mime_type, $files{$file}, "Magic type for $file is right" );
		}
	}





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These things should not work
{
my %files = qw(
	excel.abc	application/vnd.ms-excel
	excel.xls	application/vnd.ms-excel
	);

foreach my $file ( sort keys %files )
	{
	my $path = File::Spec->catfile( qw( t files files_to_test ), $file );
	ok( ! -e $file, "File $file doesn't exist ( good )" );

	my $mime_type = $bucket->_file_magic_type( $file );
	ok( ! defined $mime_type );
	}
}
