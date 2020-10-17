#!/usr/bin/env perl
# ABSTRACT: A tool to set environment variables for running ninja

use strict;
use warnings;

use Env qw(@LIBRARY_PATH @PATH);
use Cwd;
use File::Spec;

sub main {
	if( $^O eq 'MSWin32' ) {
		my $src_dir = File::Spec->catfile( getcwd() ,qw(_build src) );
		push @LIBRARY_PATH, $src_dir;
		push @PATH, $src_dir;
	}

	system('ninja', @ARGV);
}

main;
