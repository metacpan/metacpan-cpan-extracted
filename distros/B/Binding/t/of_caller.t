#!/usr/bin/env perl -w
use strict;
use Test::More tests => 4;

use Binding;

my $x = 500;

sub foo {
    my $level = shift;;
    my $b = Binding->of_caller($level);
    return $b->eval('$x + 1;');
}

sub bar {
    my $x = 42;
    foo;
}

sub baz {
    my $x = 50;
    foo;
}

is foo(1), 501;
is bar, 43;
is baz, 51;

is(
    sub {
        my $x = 3;
        sub { foo(2) }->();
    }->(),
    4
);

