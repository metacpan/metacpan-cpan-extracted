#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Warn;

use B::Hooks::AtRuntime;

# Use a fresh lexical each time, just to make sure tests don't interfere
# with each other.

{
    my @record;
    push @record, 1;
    BEGIN { at_runtime { push @record, 2 } }
    push @record, 3;

    is_deeply \@record, [1..3], "at_runtime lowers to runtime";
}

{
    my @record;
    push @record, 1;
    BEGIN {
        at_runtime { push @record, 2};
        at_runtime { push @record, 3};
    }
    push @record, 4;

    is_deeply \@record, [1..4], "multiple a_r's in one BEGIN";
}

{
    my @record;
    push @record, 1;
    BEGIN { at_runtime { push @record, 2 } }
    BEGIN { at_runtime { push @record, 3 } }
    push @record, 4;

    is_deeply \@record, [1..4], "multiple BEGINs";
}

SKIP: {
    skip "No eval{} with USE_FILTER", 1 if B::Hooks::AtRuntime::USE_FILTER;

    my @record;
    push @record, 4;
    BEGIN {
        push @record, 1;
        at_runtime { push @record, 5 };
        eval q{ BEGIN { at_runtime { push @record, 2 } } };
        push @record, 3;
    }
    push @record, 6;

    is_deeply \@record, [1..6], "multiple simultaneous BEGINs";
}

sub call_ar {
    my ($cb) = @_;
    at_runtime { $cb->() };
}

{
    my @record;
    push @record, 1;
    BEGIN {
        at_runtime { push @record, 2 };
        call_ar sub { push @record, 3 };
        at_runtime { push @record, 4 };
    }
    push @record, 5;

    is_deeply \@record, [1..5], "a_r called via a sub";
}

{
    my @record;
    BEGIN {
        package t::Use;
        $INC{"t/Use.pm"} = __FILE__;

        use B::Hooks::AtRuntime;
        sub import { 
            my (undef, $item) = @_;
            at_runtime { push @record, $item };
        }
    }

    push @record, 1;
    use t::Use "2";
    use t::Use "3";
    push @record, 4;

    is_deeply \@record, [1..4], "a_r called via use";
}

{
    my @record;
    for (1..3) {
        push @record, 1;
        BEGIN { at_runtime { push @record, 2 } }
        push @record, 3;
    }

    is_deeply \@record, [(1..3)x3], "a_r called in a loop";
}

{
    no warnings qw/closure uninitialized/;
    my @record;
    for my $x (0..2) {
        push @record, 3*$x;
        BEGIN { at_runtime { push @record, 3*$x + 1 } }
        push @record, 3*$x + 2;
    }

    is_deeply \@record, [qw/0 1 2 3 1 5 6 1 8/], 
                                "a_r not reevaluated in loop";
}

{
    my @record;
    sub callagain {
        my ($x) = @_;
        push @record, 1;
        BEGIN { at_runtime { push @record, 2 } }
        push @record, 3;
    }
    callagain $_ for 0..2;

    is_deeply \@record, [(1..3)x3], "a_r called from a sub";
}

{
    no warnings qw/closure uninitialized/;
    my @record;
    sub reeval {
        my ($x) = @_;
        push @record, 3*$x;
        BEGIN { at_runtime { push @record, 3*$x + 1 } }
        push @record, 3*$x + 2;
    }
    reeval $_ for 0..2;

    is_deeply \@record, [qw/0 1 2 3 1 5 6 1 8/], 
                                "a_r not reevaluated in sub";
}

done_testing;
