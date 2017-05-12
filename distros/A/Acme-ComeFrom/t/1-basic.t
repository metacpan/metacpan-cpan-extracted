#!/usr/bin/perl

use strict;
use subs 'fork';
use Test::More tests => 6;

BEGIN { use_ok('Acme::ComeFrom') }

sub OK  { ok(1, "comefrom @_") }
sub NOK { ok(0, "comefrom @_") }
sub func { ok(shift, 'sanity') }
sub fork { ok(1, "fork()"); 0; }

func(1);                        # Jump to the first comefrom below (&func).
func(0);                        # This will not happen.
NOK('&NAME');                   # Neither will this.

if ($] eq "Intercal") {         # This is never true, but:
    comefrom &func;             # Coming from "func(1)"...
    OK('&NAME');                # ...and OKs the test.
}

sub {                           # In another scope now.
    MY_LABEL: NOK('LABEL');     # This will not happen.

    if ($] eq "Befunge") {      # This is never true, but:
        comefrom MY_LABEL;      # Coming from "MY_LABEL" above...
        OK('LABEL');            # ...and OKs the test
    }

    EXPR0: NOK('EXPR');         # This will not happen.

    if ($] eq "APL") {          # This is never true, but:
        comefrom "EXPR$|";      # Coming from "EXPR0" above...
        OK('EXPR');             # ...and OKs the test
    }
}->();

comefrom(EXPR0);                # This causes a fork!

no Acme::ComeFrom;              # Removes filtering...
normal: OK('(disabled)');       # ...so this will run.

if ($] eq "Lisp") {             # This is never true...
    NOK('(disabled)')           # ...so this will not happen.
}

use Acme::ComeFrom;             # Resumes filtering.

{
    my $i = 0;

    DUMMY: 0;                   # This evalutes the "$i++" below.
    EXPR1: NOK('uncached EXPR');

    if ($] eq "FORTRAN") {      # This is never true, but:
        comefrom 'EXPR'.$i++;   # Coming from "EXPR1:" above...
        OK('uncached EXPR');    # ...and OKs the test
    }
}

