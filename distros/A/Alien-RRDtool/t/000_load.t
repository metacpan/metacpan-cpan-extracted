#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Alien::RRDtool';
}

diag "Testing Alien::RRDtool/$Alien::RRDtool::VERSION";
