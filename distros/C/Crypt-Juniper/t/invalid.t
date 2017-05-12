#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Crypt::Juniper;

my $warn = 0;

my @invalid = (undef, qw[ $9jadsfdf $9$asd $9$asdf*
                          $9$dLw2ajHmFnCZUnCtuEhVwYY
                          $9$dLw2ajHmFnCZUnCtuEhVw  ]);
plan tests => scalar @invalid;

for my $crypt (@invalid)
{
    # avoid undef interpolation without disabling warnings
    my $print = defined $crypt ? "'$crypt'" : 'undef';
    dies_ok { juniper_decrypt($crypt) } "Invalid crypt '$print' should return undef";
}

