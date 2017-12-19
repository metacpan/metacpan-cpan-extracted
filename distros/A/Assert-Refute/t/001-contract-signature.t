#!perl

use strict;
use warnings;
use Test::More tests => 1;

my $sig = eval {
    package T;
    require Assert::Refute;
    Assert::Refute->import();
    my $c = contract( sub {
        my $c = shift;
        $c->is($_, 42) for @_;
    }, need_object => 1 )->apply(42, 137)->signature;
};

is $sig, "t1Nd", "Signature as expected" or do {
    diag "Exception was: $@" if $@;
    print "Bail out! Signature fails\n";
};
