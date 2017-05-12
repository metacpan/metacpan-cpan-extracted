#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

{
    package Opaque;
    use Moose;

    with 'Bolts::Role::Opaque';

    sub foo { 'secret' }
}

{
    package OpaqueTest;
    use Bolts;

    artifact 'opaque' => ( class => 'Opaque' );
}

my $bag = OpaqueTest->new;

my $opaque = $bag->acquire('opaque');
isa_ok($opaque, 'Opaque');
is($opaque->foo, 'secret');

my $foo = eval {
    $bag->acquire('opaque', 'foo');
};

is($foo, undef);
like($@, qr/\bmay not examine\b/);
like($@, qr/\bopaque path\b/);

