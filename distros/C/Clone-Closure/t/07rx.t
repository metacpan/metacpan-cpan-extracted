#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use re ();
use Clone::Closure qw/clone/;

my %reimport = (
    rx      => is_regexp        =>
    pat     => regexp_pattern   =>
    must    => regmust          =>
);

for (keys %reimport) {
    no strict "refs";
    my $re = "re::$reimport{$_}";
    defined &$re and *$_ = \&$re;
}

my $tests;

{
    my $qr = qr/a/xi;
    my $cl = clone $qr;

    $tests += 1;

    ok  ref($cl),                       "cloned qr is a ref";

    if (defined &rx) {
        $tests++;
        ok  rx($cl),                    "...and a regexp";
    }

    if (defined &pat) {
        $tests += 2;
        is +(pat($cl))[0],  (pat($qr))[0],  "...with the correct pattern";
        is +(pat($cl))[1],  (pat($qr))[1],  "...and the correct flags";
    }

    if (defined &must) {
        $tests++;
        is  must($cl),      must($qr),      "...and the correct regmust";
    }
       
    $tests += 3;

    is  "$cl",  "$qr",                  "...with the correct str'n";
    ok  "a" =~ $cl,                     "...and matches";
    ok  !("b" =~ $cl),                  "...and doesn't match";
}

{
    my $rx = ${ qr/a/xi };
    defined &rx and rx($rx) or last;

    my $cl = clone $rx;

    $tests += 2;

    ok  !ref($cl),                      "cloned REGEXP is not a ref";
    ok  rx($cl),                        "...but is a regexp";

    if (defined &pat) {
        $tests += 2;
        is +(pat($cl))[0],  (pat($rx))[0],  "...with the correct pattern";
        is +(pat($cl))[1],  (pat($rx))[1],  "...and the correct flags";
    }

    if (defined &must) {
        $tests++;
        is  must($cl),      must($rx),      "...and the correct regmust";
    }
       
    $tests += 3;

    is  "$cl",  "$rx",                  "...with the correct str'n";
    ok  "a" =~ $cl,                     "...and matches";
    ok  !("b" =~ $cl),                  "...and doesn't match";
}

done_testing $tests;
