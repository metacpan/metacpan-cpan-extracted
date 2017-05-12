#!/usr/bin/perl

# Formal testing for Archive::Builder

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Class::Autouse ':devel';
use Archive::Builder ();

my @files = qw{
	a/foo.txt
        bar.txt
	a/baz.txt
};

my @expected = qw{
        a/bar.txt
	a/a/baz.txt
	a/a/foo.txt
};




####################################################################
# Section 1 - Test constructors

# Create a trivial Archive::Builder
my $builder = Archive::Builder->new;
ok( $builder, 'Archive::Builder constructor returns true' );

# Create a trivial section
my $section = Archive::Builder::Section->new( 'a' );
ok( $section, '->new( name ) with legal name returns true' );
ok( $builder->add_section($section), 'Added section' );
# Add some files
foreach my $file ( @files ) {
	ok( $section->new_file( $file, 'string', 'foo' ), 'Added file' );
}

# Get the archive
my $archive = $builder->archive('tgz');
isa_ok( $archive, 'Archive::Builder::Archive' );

# Get the sorted files
my @got = $archive->sorted_files;
is_deeply( \@got, \@expected, 'Got the expected sorted_files results' );
