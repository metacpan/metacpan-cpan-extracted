#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Warn;

use B::Hooks::AtRuntime qw/at_runtime after_runtime/;

{
    my @record;
    {
        push @record, 1;
        BEGIN { 
            after_runtime { push @record, 7 };
            at_runtime { push @record, 2 };
        }
        push @record, 3;
        BEGIN { at_runtime { push @record, 4 } }
        BEGIN { after_runtime { push @record, 6 } }
        push @record, 5;
    }

    is_deeply \@record, [1..7],     "after_r called correctly";
}

{
    package t::Caller;
    use B::Hooks::AtRuntime qw/at_runtime after_runtime/;
    my ($at, $after);

    sub call_after {
        my $x = [];
        BEGIN { after_runtime { $after = caller } }
    }

    sub check_caller { 
        BEGIN { at_runtime { $at = caller; } }
        call_after;
    }

    package main;
    t::Caller::check_caller();
    is $at, "t::Caller",            "at_r does not add extra scope";
    is $after, "t::Caller",         "after_r does not add extra scope";
}

done_testing;
