use strict;
use warnings;

use Test2::V0;

use DateTime;
use DateTime::Format::ISO8601;

my $dt = DateTime->new(
    year      => 2016,
    month     => 2,
    day       => 2,
    hour      => 5,
    minute    => 6,
    second    => 7,
    time_zone => 'UTC',
    formatter => 'DateTime::Format::ISO8601',
);

is( "$dt", '2016-02-02T05:06:07Z', 'default format in UTC' );

$dt = DateTime->new(
    year      => 2016,
    month     => 2,
    day       => 2,
    hour      => 5,
    minute    => 6,
    second    => 7,
    time_zone => 'America/Chicago',
    formatter => 'DateTime::Format::ISO8601',
);

is(
    "$dt",
    '2016-02-02T05:06:07-06:00',
    'default format in America/Chicago DST',
);

$dt = DateTime->new(
    year       => 2016,
    month      => 2,
    day        => 2,
    hour       => 5,
    minute     => 6,
    second     => 7,
    nanosecond => 123,
    time_zone  => 'America/Chicago',
    formatter  => 'DateTime::Format::ISO8601',
);

is(
    "$dt",
    '2016-02-02T05:06:07.000000123-06:00',
    'default format with nanoseconds in America/Chicago DST',
);

$dt = DateTime->new(
    year       => 2016,
    month      => 2,
    day        => 2,
    hour       => 5,
    minute     => 6,
    second     => 7,
    nanosecond => 123000000,
    time_zone  => 'America/Chicago',
    formatter  => 'DateTime::Format::ISO8601',
);

is(
    "$dt",
    '2016-02-02T05:06:07.123-06:00',
    'default format with milliseconds in America/Chicago DST',
);

$dt = DateTime->new(
    year      => 2016,
    month     => 2,
    day       => 2,
    hour      => 5,
    minute    => 6,
    second    => 7,
    time_zone => 'UTC',
);

is(
    +DateTime::Format::ISO8601->format_datetime($dt),
    '2016-02-02T05:06:07Z',
    'default format in UTC, called as class method',
);

done_testing();
