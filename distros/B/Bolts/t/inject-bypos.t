#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

{
    package Bag;
    use Bolts;

    use Test::More;

    artifact bypos => (
        builder => sub {
            my ($builder, $bag, $name, @params) = @_;
            is($params[0], 42);
            is($params[1], 'foo');
            is($params[2], 'bar');
            return [];
        },
        parameters => [
            value 42,
            value 'foo',
            value 'bar',
        ],
    );
}

my $bag = Bag->new;
my $bypos = $bag->acquire('bypos');
