#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use Continuation::Escape;

my @reached;

call_cc {
    call_cc {
        eval {
            shift->();
        };
        push @reached, "inside";
    };
    push @reached, "outside";
};

is_deeply([splice @reached], ["outside"]);

