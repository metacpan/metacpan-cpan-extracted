# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { use_ok('DBD::Sys'); }

do "t/lib.pl";

my @proved_vers = proveRequirements();

diag("Testing DBD::Sys $DBD::Sys::VERSION, Perl $], $^X on $^O");
showRequirements(@proved_vers);
