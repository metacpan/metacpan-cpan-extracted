#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Schema;
    use Moose;
}

{
    package Thing;
    use Moose;

    has schema => (
        is       => 'ro',
        isa      => 'Schema',
        required => 1,
    );

    has foo => (
        is       => 'ro',
        required => 1,
    );

    has bar => (
        is       => 'ro',
        required => 1,
    );
}

{
    package Model;
    use Moose;
    use Bread::Board::Declare;

    has schema => (
        is  => 'ro',
        isa => 'Schema',
    );

    has thing => (
        is           => 'ro',
        isa          => 'Thing',
        dependencies => ['schema'],
        parameters   => ['foo', 'bar'],
    );
}

my $m = Model->new;
like(
    exception { $m->thing },
    qr/Mandatory parameters .* missing/,
    "error with unsatisfied parameters"
);
is(
    exception {
        my $thing = $m->resolve(
            service => 'thing',
            parameters => { foo => 'a', bar => 'b' },
        );
        is($thing->foo, 'a');
        is($thing->bar, 'b');
        isa_ok($thing->schema, 'Schema');
    },
    undef,
    "no error with satisfied parameters"
);

done_testing;
