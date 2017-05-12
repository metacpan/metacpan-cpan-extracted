#!/usr/bin/env perl

use Test::More tests => 4;
use strict;
use warnings FATAL => "all";
use Alien::GMP;
use File::Spec::Functions qw(catdir catfile);

my $inc_dir = Alien::GMP::inc_dir() =~ /Alien-GMP/
	# If GMP was compiled, look for inc_dir in build directory instead of
	# eventual install location:
	? catdir qw(share include)
	: Alien::GMP::inc_dir();
my $gmp_h = catfile($inc_dir, "gmp.h");
ok -d $inc_dir, "GMP include directory exists";
ok -f $gmp_h, "GMP header file exists";

my $lib_dir = Alien::GMP::lib_dir() =~ /Alien-GMP/
	# Same as above for lib_dir:
	? catdir qw(share lib)
	: Alien::GMP::lib_dir();
my $libgmp_so = catfile($lib_dir, "libgmp.so");
ok -d $lib_dir, "GMP lib directory exists";
ok -f $libgmp_so, "GMP shared object exists";
