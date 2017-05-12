#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 4;
use Test::LeakTrace;
use CGI::Struct::XS;

my $inp = {
    'a'       => 1,
    'b.c'     => 2,
    'd[0]'    => 3,
    'd[4]'    => 4,
    'e{a}.x'  => 5,
    'e{a}.y'  => 6,
    'f{a}[0]' => 7,
    'f{a}[1]' => 8,
    'g[]'     => 1,
    'k[]'     => ['a','b'],
    'm'       => "\0",
    'n'       => "\0\0",
    'o'       => { a => { b => 1 } },
};

no_leaks_ok {
    my @errs;
    my $hval = build_cgi_struct $inp, \@errs, { nullsplit => 0, nodot => 0, dclone => 0 };
};

no_leaks_ok {
    my @errs;
    my $hval = build_cgi_struct $inp, \@errs, { nullsplit => 1, nodot => 0, dclone => 0 };
};

no_leaks_ok {
    my @errs;
    my $hval = build_cgi_struct $inp, \@errs, { nullsplit => 0, nodot => 1, dclone => 0 };
};

no_leaks_ok {
    my @errs;
    my $hval = build_cgi_struct $inp, \@errs, { nullsplit => 0, nodot => 0, dclone => 1 };
};
