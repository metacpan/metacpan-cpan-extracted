#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Parent;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        is    => 'ro',
        isa   => 'Str',
        value => 'parent',
    );

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            my $s = shift;
            return $s->param('foo') . ' ' . 'parent';
        },
        dependencies => ['foo'],
    );
}

{
    package Child1;
    use Moose;
    use Bread::Board::Declare;

    extends 'Parent';

    has foo => (
        is    => 'ro',
        isa   => 'Str',
        value => 'child',
    );
}

{
    package Child2;
    use Moose;
    use Bread::Board::Declare;

    extends 'Parent';

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            my $s = shift;
            return $s->param('foo') . ' ' . 'child';
        },
        dependencies => ['foo'],
    );
}

{
    package Child3;
    use Moose;
    use Bread::Board::Declare;

    extends 'Child1';

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            my $s = shift;
            return $s->param('foo') . ' ' . 'child';
        },
        dependencies => ['foo'],
    );
}

with_immutable {
{
    my $obj = Parent->new;
    is($obj->foo, 'parent');
    is($obj->bar, 'parent parent');
}

{
    my $obj = Child1->new;
    is($obj->foo, 'child');
    is($obj->bar, 'child parent');
}

{
    my $obj = Child2->new;
    is($obj->foo, 'parent');
    is($obj->bar, 'parent child');
}

{
    my $obj = Child3->new;
    is($obj->foo, 'child');
    is($obj->bar, 'child child');
}
} 'Parent', 'Child1', 'Child2', 'Child3';

done_testing;
