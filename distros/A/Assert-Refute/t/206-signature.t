#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute qw(:core);
use Assert::Refute::Contract qw(contract);

my $c = contract {
    my $c = shift;
    $c->is( shift, 42 );
    $c->like( shift, qr/foo/ );
    die "Intentional" if shift;
} need_object=>1;

is $c->apply( 42, "food" )->get_sign, "t2d", "Passing contract";

is $c->apply( 42, "bard" )->get_sign, "t1Nd", "Failing contract";

is $c->apply( 42, "food", "kaboom" )->get_sign, "t2E", "Exception => fail";

done_testing;
