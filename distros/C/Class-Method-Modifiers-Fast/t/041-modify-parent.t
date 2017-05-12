#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

my @calls;

do {
    package Parent;
    sub foo { push @calls, 'Parent::foo' }

    package Child;
    use Class::Method::Modifiers::Fast;
    our @ISA = 'Parent';

    around foo => sub {
        push @calls, 'before Child::foo';
        shift->(@_);
        push @calls, 'after Child::foo';
    };
};

Child->foo;
is_deeply([splice @calls], [
    'before Child::foo',
    'Parent::foo',
    'after Child::foo',
]);

do {
    package Parent;
    use Class::Method::Modifiers::Fast;
    around foo => sub {
        push @calls, 'before Parent::foo';
        shift->(@_);
        push @calls, 'after Parent::foo';
    };
};

Child->foo;

TODO: {
    local $TODO = "pending discussion with stevan";
    is_deeply([splice @calls], [
        'before Child::foo',
        'before Parent::foo',
        'Parent::foo',
        'after Parent::foo',
        'after Child::foo',
    ]);
}
