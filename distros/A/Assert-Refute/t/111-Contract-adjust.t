#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::Contract;

{
    package Foo;
    use parent qw(Assert::Refute::Report);
};

my $spec = Assert::Refute::Contract->new(
    code => sub {
        $_[0]->is( 42, 137 );
    },
    need_object => 1,
);

my $spec2 = $spec->adjust( driver => 'Foo' );

my $rep = $spec2->apply();

isa_ok( $rep, 'Foo', "New contract" );
isa_ok( $rep, 'Assert::Refute::Report', "Nevertheless, new contract" );
is( $rep->get_sign, "tNd", "1 test failed" );

done_testing;

