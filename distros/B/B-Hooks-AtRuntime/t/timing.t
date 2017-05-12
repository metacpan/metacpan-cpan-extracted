#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Warn;
use t::Util;

use B::Hooks::AtRuntime;
use Sub::Name "subname";

# this must come before evals_ok, otherwise the eval won't see the 'our'
our @Record;

sub evals_ok {
    my ($code, $name) = @_;
    undef $@;
    eval $code;
    ok !$@, $name or diag "\$\@: $@";
}

sub evals_nok {
    my ($code, $err, $name) = @_;
    my $rv = eval $code;
    if (defined $@) {
        like $@, $err, $name;
    }
    else {
        fail $name;
        diag "eval succeeded unexpectedly";
    }
}


throws_ok { at_runtime { 1 } }
    qr/^You must call at_runtime at compile time/,
    "at_runtime at runtime fails properly";


@Record = ();
push @Record, 1;
BEGIN { at_runtime { push @Record, 2 } }
fakerequire "a_r", q{ 
    push @Record, 3;
    BEGIN { at_runtime { push @Record, 4 } }
    push @Record, 5;
    1;
};
BEGIN { at_runtime { push @Record, 6 } }
push @Record, 7;

is_deeply \@Record, [1..7], "a_r in BEGIN in require runs at the right time";


@Record = ();
push @Record, 1;
fakerequire "a_r2", q{
    push @Record, 2;
    BEGIN { at_runtime { push @Record, 3 } }
    push @Record, 4;
    1;
};
BEGIN { at_runtime { push @Record, 5 } }
push @Record, 6;

is_deeply \@Record, [1..6], "2-deep BEGIN before 1-deep";


{
    no warnings "redefine";
    # this doesn't use require, but does do things at BEGIN time, so use
    # a private lexical
    my @record;
    push @record, "start";
    BEGIN {
        push @record, "start BEGIN";
        at_runtime { push @record, "BEGIN AR 1" };
        BEGIN { at_runtime { push @record, "BEGIN BEGIN 1 AR" } }

        *BEGIN = subname "BEGIN", sub { 
            at_runtime { push @record, "BEGIN &BEGIN AR" };
        };
        &BEGIN;

        BEGIN { at_runtime { push @record, "BEGIN BEGIN 2 AR" } }
        at_runtime { push @record, "BEGIN AR 2" };
        push @record, "end BEGIN";
    }
    push @record, "end";

    my @want = (
        "start BEGIN",
        "BEGIN BEGIN 1 AR",
        "BEGIN BEGIN 2 AR",
        "end BEGIN",
        "start",
        "BEGIN AR 1",
        "BEGIN &BEGIN AR",
        "BEGIN AR 2",
        "end",
    );
    is_deeply \@record, \@want, "&BEGIN doesn't confuse us"
        or diag "GOT:\n[@record]\nWANT:\n[@want]";
}

@Record = ();
fakerequire "lines", q{
    push @Record, __LINE__;
    BEGIN { at_runtime { 1; } }
    push @Record, __LINE__;
    1;
};

is_deeply \@Record, [2,4], "at_runtime doesn't confuse line numbering";


if (B::Hooks::AtRuntime::USE_FILTER) {
    
    evals_nok q{ BEGIN { at_runtime { 1 } } },
        qr/^Can't use at_runtime from a string eval/,
        "at_runtime in eval'' fails with USE_FILTER";

    warning_is {
        fakerequire "eol", q{ 
            BEGIN { at_runtime { 1 } } 1;
            1;
        };
    }   "Extra text '1;' after call to lex_stuff",
        "at_runtime not at EOL warns";

    warnings_are {
        fakerequire "eolcomment", q{
            BEGIN { at_runtime { 1 } }  	# foobar
            1;
        };
    }   [],
        "comments and whitespace before EOL ignored";
}
else {

    @Record = ();
    evals_ok q{ 
        push @Record, 1;
        BEGIN { at_runtime { push @Record, 2 } }
        push @Record, 3;
    }, "at_runtime in eval'' works";

    is_deeply \@Record, [1..3], "at_runtime in eval'' runs properly";

    @Record = ();
    warnings_are { fakerequire "eol", q{
        push @Record, 1;
        BEGIN { at_runtime { push @Record, 2 } } push @Record, 3;
        1;
    } } [],
        "code before EOL doesn't warn";
    is_deeply \@Record, [1..3], "code before EOL runs properly";

    @Record = ();
    fakerequire "eolline", q{
        push @Record, __LINE__;
        BEGIN { at_runtime { 1 } } push @Record, __LINE__;
        push @Record, __LINE__;
        1;
    };
    is_deeply \@Record, [2..4], "code before EOL sees correct __LINE__";
}

done_testing;
