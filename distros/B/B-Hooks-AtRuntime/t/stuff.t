#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use B::Hooks::AtRuntime qw/at_runtime lex_stuff/;

{
    my @record;
    push @record, 1;
    BEGIN { lex_stuff q{ push @record, 2; } }
    push @record, 3;

    is_deeply \@record, [1..3], "lex_stuff runs at runtime";
}

{
    my @record;
    push @record, 1;
    BEGIN { lex_stuff q{ push @record, 2; } }
    BEGIN { lex_stuff q{ push @record, 3; } }
    push @record, 4;

    is_deeply \@record, [1..4], 
        "multiple BEGINs stuff in forwards order";
}

{
    my @record;
    push @record, 1;
    BEGIN {
        lex_stuff q{ push @record, 3; };
        lex_stuff q{ push @record, 2; };
    }
    push @record, 4;

    is_deeply \@record, [1..4], 
        "multiple stuffs from one BEGIN in reverse order";
}

local $" = "]\n[";

{
    my @record;
    push @record, "start";
    BEGIN {
        push @record, "start BEGIN";
        at_runtime { push @record, "BEGIN AR" };
        BEGIN {
            push @record, "start BEGIN BEGIN";
            at_runtime { push @record, "BEGIN BEGIN AR" };
            my $code = q{ 
                push @record, "start BEGIN BEGIN LS";
                at_runtime { push @record, "BEGIN BEGIN LS AR" }; 
                push @record, "end BEGIN BEGIN LS";
            };
            $code =~ s/\n/ /g;
            lex_stuff $code;
            push @record, "end BEGIN BEGIN";
        }
        push @record, "end BEGIN";
    }
    push @record, "end";

    my @want = (
        "start BEGIN BEGIN",
        "end BEGIN BEGIN",
        "start BEGIN",
        "start BEGIN BEGIN LS",
        "end BEGIN BEGIN LS",
        "BEGIN BEGIN AR",
        "end BEGIN",
        "start",
        "BEGIN AR",
        "BEGIN BEGIN LS AR",
        "end",
    );
    is_deeply \@record, \@want, "a_r in l_s"
        or diag "GOT:\n[@record]\nWANT:\n[@want]";
}

{
    my @record;
    push @record, "start";
    BEGIN {
        push @record, "start BEGIN";
        at_runtime { push @record, "BEGIN AR" };
        lex_stuff q{push @record, "BEGIN LS";};
        my $code = q{ 
            push @record, "start BEGIN LS";
            BEGIN { 
                push @record, "start BEGIN LS BEGIN";
                at_runtime { push @record, "BEGIN LS BEGIN AR" }; 
                push @record, "end BEGIN LS BEGIN";
            }
            push @record, "end BEGIN LS";
        };
        $code =~ s/\n/ /g;
        lex_stuff $code;
        push @record, "end BEGIN";
    }
    push @record, "end";

    my @want = (
        "start BEGIN",
        "end BEGIN",
        "start BEGIN LS BEGIN",
        "end BEGIN LS BEGIN",
        "start",
        "start BEGIN LS",
        #"BEGIN LS BEGIN AR",
        "end BEGIN LS",
        "BEGIN LS",
        "BEGIN AR",
        # This is delayed from where it would have been expected because
        # BHAR::clear wasn't run early enough.
        "BEGIN LS BEGIN AR",
        "end",
    );
    is_deeply \@record, \@want, "a_r in BEGIN in l_s"
        or diag "GOT:\n[@record]\nWANT:\n[@want]";
}

done_testing;
