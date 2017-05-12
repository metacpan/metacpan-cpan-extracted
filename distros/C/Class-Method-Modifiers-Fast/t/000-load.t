#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

do {
    package Class;
    use Class::Method::Modifiers::Fast;

    sub foo { }

    before foo => sub {
    };

    after foo => sub {
    };

    around foo => sub {
    };
};

pass("loaded correctly");

