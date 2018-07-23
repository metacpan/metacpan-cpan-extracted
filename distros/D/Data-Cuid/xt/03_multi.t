#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'Testing multi-process collisions only upon release'
        unless $ENV{RELEASE_TESTING};
}

use IO::Async::Loop;
use IO::Async::Function;

use Data::Cuid;

my $loop = IO::Async::Loop->new;

my $max  = 1_200_000;
my $proc = 3;

plan tests => 2;

my @func;
my $test = sub {
    my ( $fn, $ids ) = @_;

    for ( 1 .. $proc ) {
        my $func = IO::Async::Function->new(
            code => sub {
                map { $fn->() } 1 .. $max;
            }
        );
        $loop->add($func);
        my $f = $func->call( args => [] );
        $f->on_done( sub { $ids->{$_}++ for @_ } );
        push @func, $f;
    }
};

$test->( \&Data::Cuid::cuid, \my %cuids );

$loop->await_all(@func);

is keys %cuids, $max * $proc, 'got all unique cuids';

TODO: {
    local $TODO = 'slugs are more likely to collide';

    @func = ();
    $test->( \&Data::Cuid::slug, \my %slugs );

    $loop->await_all(@func);

    is keys %slugs, $max * $proc, 'got all unique slugs';
}
