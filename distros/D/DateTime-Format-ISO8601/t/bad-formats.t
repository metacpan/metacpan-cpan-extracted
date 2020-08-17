# Copyright (C) 2003-2012  Joshua Hoblitt
use strict;
use warnings;

use Test2::V0;

use DateTime::Format::ISO8601;

# parse_datetime
my $base_year  = 2000;
my $base_month = '01';
my $iso8601    = DateTime::Format::ISO8601->new(
    base_datetime =>
        DateTime->new( year => $base_year, month => $base_month ),
);

# examples from https://rt.cpan.org/Ticket/Update.html?id=5264

# Section 4.2.5.1 says "Expressions of the difference between local time and
# UTC of day are a component in the representations defined in 4.2.5.2; they
# shall not be used as self-standing expressions.". Which means the UTC offset
# is considered part of the time format so you get to use the extended
# formation (the ':') or not but you can't mix and match the two.

like(
    dies {
        my $dt = $iso8601->parse_datetime('2009-12-10T09:00:00.00+0100');
    },
    qr/Invalid date format/,
    'extended format with TZ',
);

# more "colon or not" coverage
like(
    dies {
        my $dt = $iso8601->parse_datetime('20091210T090000.00+01:00');
    },
    qr/Invalid date format/,
    'extended format with TZ',
);

like(
    dies {
        my $dt = $iso8601->parse_datetime('20110704T205023+02:00');
    },
    qr/Invalid date format/,
    'extended format with TZ',
);

done_testing();

