#!perl -T
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 1;

BEGIN {
    for my $module (qw(Alien::BWIPP)) {
        use_ok($module) or BAIL_OUT("could not load $module, cannot continue");
        diag("Testing $module " . $module->VERSION);
    }
}
