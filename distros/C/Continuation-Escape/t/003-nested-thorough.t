#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Continuation::Escape;

my @points;
sub test_escape {
    my $return_from = shift;

    call_cc {
        my $outer = shift;

        my $ret = call_cc {
            my $inner = shift;

            push @points, "a";
            $outer->("from outer") if $return_from eq "outer";
            push @points, "b";
            $inner->("from inner") if $return_from eq "inner";
            push @points, "c";
            "fell off";
        };

        push @points, "d";

        $ret;
    };
}

is(test_escape("outer"), "from outer");
is_deeply([splice @points], ["a"]);

is(test_escape("inner"), "from inner");
is_deeply([splice @points], ["a", "b", "d"]);

is(test_escape("xxxxx"), "fell off");
is_deeply([splice @points], ["a", "b", "c", "d"]);
