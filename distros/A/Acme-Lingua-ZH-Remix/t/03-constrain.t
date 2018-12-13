#!/usr/bin/env perl
use strict;
use utf8;
use Test::More 0.98;
use Acme::Lingua::ZH::Remix;

my $r = Acme::Lingua::ZH::Remix->new;

my ($min, $max) = (5, 8);

for (1..100) {
    my $s = $r->random_sentence(min => $min, max => $max);
    my $l = length($s);

    utf8::encode($s);
    ok($l >= $min && $l <= $max, "length: $min <= $l <= $max");
}


done_testing;

