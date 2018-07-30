#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute::Contract;

my $spec = Assert::Refute::Contract->new( code => sub {
    my $c = shift;
    $c->refute( shift, shift );
    die if shift;
}, need_object => 1 );

ok  $spec->apply( 0, "fine" )->is_passing, "Good";
ok !$spec->apply( 1, "not so fine" )->is_passing, "Bad";
ok !$spec->apply( 0, "fine", "die" )->is_passing, "Ugly";

done_testing;
