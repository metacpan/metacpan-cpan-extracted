#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use Continuation::Escape;

sub apply {
    my $cont = shift;
    my $arg = shift;

    $cont->($arg);
}

my $ret = call_cc {
    my $escape = shift;
    apply($escape, "yo");
};

is($ret, "yo");

