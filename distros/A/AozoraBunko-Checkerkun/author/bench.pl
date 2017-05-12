#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Encode    qw//;
use Benchmark qw/cmpthese/;

my $ENC  = Encode::find_encoding("Shift_JIS");
my $char = '💓';

cmpthese(-1, {
    'is_gaijiA', sub { is_gaijiA($char) },
    'is_gaijiB', sub { is_gaijiB($char) },
});

sub is_gaijiA
{
    my $char = shift;
    return length $ENC->encode($char, Encode::FB_QUIET) ? 1 : 0;
}

sub is_gaijiB
{
    my $char = shift;
    eval { $ENC->encode($char, Encode::FB_CROAK) };
    return $@ ? 1 : 0;
}
