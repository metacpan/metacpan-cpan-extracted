package Acme::VOYAGEGROUP::ConferenceRoom::Output::Color;
use strict;
use warnings;
use utf8;

sub convert {
    my $class = shift;
    my $lines = shift;

    join "\n", map { $_ =~ s!(/+)!\e[31m$1\e[m!; $_ } @{$lines};
}

1;
