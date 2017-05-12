package Acme::VOYAGEGROUP::ConferenceRoom::Output::JSON;
use strict;
use warnings;
use utf8;
use JSON::XS;

sub convert {
    my $class = shift;
    my $lines = shift;

    encode_json {
        conference_room => join "\n", @{$lines}
    };
}

1;
