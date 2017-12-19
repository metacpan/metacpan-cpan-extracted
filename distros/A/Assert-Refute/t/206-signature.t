#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute qw(:core);

my $c = contract {
    my $c = shift;
    $c->is( shift, 42 );
    $c->like( shift, qr/foo/ );
    die "Intentional" if shift;
} need_object=>1;

is $c->apply( 42, "food" )->signature, "t2d", "Passing contract";

is $c->apply( 42, "bard" )->signature, "t1Nd", "Failing contract";

is $c->apply( 42, "food", "kaboom" )->signature, "t2NE", "Exception => fail";

done_testing;
