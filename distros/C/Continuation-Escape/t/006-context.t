#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Continuation::Escape;

my ($foo, $bar) = call_cc {
    shift->("foo", "bar");
};

is($foo, "foo");
is($bar, "bar");

my $baz = call_cc {
    shift->("foo", "bar");
};

is($baz, "foo");

