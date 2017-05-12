#!/usr/bin/perl

# Compile testing for CPAN::Mini::Extract

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok('CPAN::Mini::Extract');
