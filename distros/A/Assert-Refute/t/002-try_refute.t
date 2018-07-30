#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More tests => 1;

use Assert::Refute {};

my $sign = eval {
    try_refute {
        my $contract = shift;
        $contract->refute( 0, "pass" );
        $contract->refute( 1, "fail" );
    }->get_sign
};
my $err = $@;

unless (is $sign, "t1Nd", "Signature as expected") {
    diag "Exception was: $err" if $err;
    print "Bail out! Basic try_refute{ ... } fails\n";
};
