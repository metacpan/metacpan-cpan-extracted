package Acme::VOYAGEGROUP::ConferenceRoom::Output::MessagePack;
use strict;
use warnings;
use utf8;
use Data::MessagePack;

sub convert {
    my $class = shift;
    my $lines = shift;

    my $mp = Data::MessagePack->new();

    $mp->pack({conference_room => join "\n", @{$lines}});
}

1;
