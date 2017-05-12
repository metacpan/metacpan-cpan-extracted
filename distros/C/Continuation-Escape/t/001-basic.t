#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use Continuation::Escape;

my $result = call_cc {
    my $escape = shift;

    sub { $escape->("escaped!") }->();

    fail("This should never be reached");
};

is($result, "escaped!");
