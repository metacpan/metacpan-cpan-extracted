#!/usr/bin/perl

use lib qw(t);
use Test::Arepa::T01Smoke;
use Test::More;

if (exists $ENV{REPREPRO4PATH} and -x $ENV{REPREPRO4PATH} &&
        $ENV{AREPASUDOCONFIGURED}) {
    Test::Class->runtests;
}
else {
    plan skip_all => "To run these tests, specify the reprepro 4 path in \$REPREPRO4PATH and set \$AREPASUDOCONFIGURED to 1";
}
