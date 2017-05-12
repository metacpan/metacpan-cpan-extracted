#!/usr/bin/perl
use warnings;
use strict;
use 5.010;
use Test::More;
use DateTime::Calendar::Discordian;

for my $i (1 .. 73) {
    my $cardinal = $i;
    given ($i) {
        when ($i % 10 == 1 && $i != 11) { $cardinal .= 'st' }
        when ($i % 10 == 2 && $i != 12) { $cardinal .= 'nd' }
        when ($i % 10 == 3 && $i != 13) { $cardinal .= 'rd' }
        default  { $cardinal .= 'th' }
    };
    is(DateTime::Calendar::Discordian::_cardinal($i), $cardinal, "date $i");
}

done_testing();
