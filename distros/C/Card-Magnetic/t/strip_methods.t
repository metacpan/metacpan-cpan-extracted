#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Dumper;

use_ok( 'Card::Magnetic');

my @tracks = qw/
%A0000000000000000^RECSKY^171700012345888?
;0000000000000000^171700012345888?
;240000000000000000^1232343456456756786778901239011223171712345678903456789?
/;

my $stripe = join "\n", @tracks, "";

my $structure = {
    tracks =>[
        qw/
%A0000000000000000^RECSKY^171700012345888?
;0000000000000000^171700012345888?
;240000000000000000^1232343456456756786778901239011223171712345678903456789?
        /,
    ],
};

my $card = Card::Magnetic->new();
$card->stripe( $stripe );
$card->parse();

is_deeply( $card->{ tracks }, $structure->{ tracks }, "Tracks from the card"  );

is( $card->track1(), $tracks[0], "Track 1");
is( $card->track2(), $tracks[1], "Track 2");
is( $card->track3(), $tracks[2], "Track 3");

done_testing();
