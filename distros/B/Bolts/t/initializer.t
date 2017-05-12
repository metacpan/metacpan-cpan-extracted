#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;
use Bolts::Util qw( bolts_init );

{
    package TestApp::Bag;
    use Bolts;

    artifact foo => (
        builder => sub { [] },
        push    => [
            option { required => 1, isa => 'Int' },
        ],
    );

    artifact bar => (
        builder => sub { [] },
        push    => [
            value "xyz",
            value "abc",
            value "mno",
        ],
    );
}
{
    package TestApp::Foo;
    use Moose;

    with 'Bolts::Role::Initializer';

    sub init_locator { TestApp::Bag->new }

    has thing => (
        is          => 'ro',
        isa         => 'ArrayRef',
        traits      => [ 'Bolts::Initializer' ],
    );
}

#diag(explain(TestApp::Foo->meta));

{
    my $foo = TestApp::Foo->new(
        thing => bolts_init('foo', { 0 => 42 }),
    );
    isa_ok($foo, 'TestApp::Foo');

    my $thing = $foo->thing;
    is_deeply($thing, [ 42 ]);
}

{
    my $foo = TestApp::Foo->new(
        thing => bolts_init('bar'),
    );
    isa_ok($foo, 'TestApp::Foo');

    my $thing = $foo->thing;
    is_deeply($thing, [ 'xyz', 'abc', 'mno' ]);
}

