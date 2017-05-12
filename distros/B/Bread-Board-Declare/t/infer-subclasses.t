#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package NonMoose;
    BEGIN { $INC{'NonMoose.pm'} = __FILE__ }
    sub new { bless { data => $_[0] }, shift }
}

{
    package Foo;
    use Moose;

    has non_moose => (
        is       => 'ro',
        isa      => 'NonMoose',
        required => 1,
    );
}

{
    package Bar;
    use Moose;

    has foo => (
        is       => 'ro',
        isa      => 'Foo',
        required => 1,
    );
}

{
    package Container;
    use Moose;
    use Bread::Board::Declare;

    has non_moose => (
        is    => 'ro',
        isa   => 'NonMoose',
        block => sub { NonMoose->new("blah") },
    );

    has foo => (
        is           => 'ro',
        isa          => 'Foo',
        dependencies => ['non_moose'],
    );

    has bar => (
        is    => 'ro',
        isa   => 'Bar',
        infer => 1,
    );
}

{
    my $c = Container->new;
    my $bar = $c->bar;
    isa_ok($bar->foo->non_moose, 'NonMoose');
}

{
    package Foo::Sub;
    use Moose;

    extends 'Foo';
}

{
    package Container2;
    use Moose;
    use Bread::Board::Declare;

    has non_moose => (
        is    => 'ro',
        isa   => 'NonMoose',
        block => sub { NonMoose->new("blah") },
    );

    has foo => (
        is           => 'ro',
        isa          => 'Foo::Sub',
        dependencies => ['non_moose'],
    );

    has bar => (
        is    => 'ro',
        isa   => 'Bar',
        infer => 1,
    );
}

{
    my $c = Container2->new;
    my $bar = $c->bar;
    isa_ok($bar->foo->non_moose, 'NonMoose');
}

done_testing;
