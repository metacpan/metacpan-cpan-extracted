#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use DateTime::Format::EXIF;

my @cases = (
    [ '2019:11:04 18:27:23'             => '2019-11-04T18:27:23', 0, 'floating' ],
    [ '2019:11:04 18:27:23.62'          => '2019-11-04T18:27:23', 620000000, 'floating' ],
    [ '2019:11:04 18:27:23.625221'      => '2019-11-04T18:27:23', 625221000, 'floating' ],
    [ '2019:11:04 18:27:23Z'            => '2019-11-04T18:27:23', 0, 'UTC', 0 ],
    [ '2019:11:04 18:27:23.625Z'        => '2019-11-04T18:27:23', 625000000, 'UTC', 0 ],
    [ '2019:11:04 18:27:23+03:00'       => '2019-11-04T18:27:23', 0, '+0300', 3 * 60 * 60 ],
    [ '2019:11:04 18:27:23-02:30'       => '2019-11-04T18:27:23', 0, '-0230', -2.5 * 60 * 60 ],
);

for my $case (@cases) {
    my ($in, $iso, $ns, $tz, $offset) = @$case;
    my $dt = DateTime::Format::EXIF->parse_datetime($in);
    is $dt->iso8601(), $iso, "$in iso";
    is $dt->nanosecond(), $ns, "$in ns";
    is $dt->time_zone->name, $tz, "$in tzname";
    if (defined $offset) {
        is $dt->offset, $offset, "$in offset";
    }
}

done_testing();

