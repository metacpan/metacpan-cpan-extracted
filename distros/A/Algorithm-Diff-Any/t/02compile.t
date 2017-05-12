#!/usr/bin/perl

# t/02compile.t
#  Check that the module can be compiled and loaded properly.
#
# $Id: 02compile.t 10346 2009-12-03 01:53:25Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings; # 1 test

# Check that we can load the module
BEGIN {
  use_ok('Algorithm::Diff');
  use_ok('Algorithm::Diff::Any');
}
