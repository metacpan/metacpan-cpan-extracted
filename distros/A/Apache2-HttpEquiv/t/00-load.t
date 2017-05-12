#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Apache2::HttpEquiv');
}

diag("Testing Apache2::HttpEquiv $Apache2::HttpEquiv::VERSION");
