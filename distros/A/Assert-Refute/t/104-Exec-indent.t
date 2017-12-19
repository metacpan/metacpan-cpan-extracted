#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::Exec;

my $c = Assert::Refute::Exec->new( indent => 1 );

$c->refute (0);
$c->diag( "Foobar" );
$c->done_testing;

is $c->as_tap, <<"TAP", "Tap indented as intended";
    ok 1
    # Foobar
    1..1
TAP

done_testing;
