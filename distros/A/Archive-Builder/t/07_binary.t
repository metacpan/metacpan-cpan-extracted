#!/usr/bin/perl

# Some tests for binary files

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Flat;
use Archive::Builder;

# Create our Generator 
use vars qw{$Generator $Section};
sub init {
	$Generator = Archive::Builder->new();
	$Section = $Generator->new_section('section');
	$Section->new_file( 'text', 'main::direct', 'This is a text file' );
	$Section->new_file( 'binary', 'main::direct', "Binary\000files\000contain\000nulls" );
}
init();







########################################################################
# Save tests

# Adding additional file_count test in
is( $Generator->file_count, 2, '->file_count is correct' );
ok( defined $Generator->section('section')->file('text')->binary, '->binary on text file returns defined' );
ok( ! $Generator->section('section')->file('text')->binary, '->binary on text file returns false' );
ok( defined $Generator->section('section')->file('binary')->binary, '->binary on binary file returns defined' );
ok( $Generator->section('section')->file('binary')->binary, '->binary on binary file returns true' );

sub direct {
	my $File = shift;
	my $contents = shift;
	\$contents;
}
