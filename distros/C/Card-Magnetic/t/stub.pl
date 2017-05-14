#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Test::More;

use Card::Magnetic;

my $stripe = <<EOF;
%A0000000000000000^RECSKY^171700012345888?
;0000000000000000^171700012345888?
;0000000000000000^1232343456456756786778901239011223171712345678903456789?
EOF

my $card = Card::Magnetic->new();

$card->stripe( $stripe );

my $strips = $card->parse();

print Dumper $card;
