package Acme::VOYAGEGROUP::ConferenceRoom::Output::XML;
use strict;
use warnings;
use utf8;
use XML::Smart;

sub convert {
    my $class = shift;
    my $lines = shift;

    my $xml = XML::Smart->new;
    $xml->{conference_room} = join "\n", @{$lines};

    scalar $xml->data;
}

1;
