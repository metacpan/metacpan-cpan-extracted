#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true false);

use DateTime;
use DateTime::Format::Natural;
use DateTime::TimeZone;
use Test::More tests => 12;

eval { DateTime::Format::Natural->new(lang => 'en') };
ok(!$@, 'lang');

my @formats = qw(
    d/m/y
    mm/dd/yy
    yyyy-mm-dd
);
foreach my $format (@formats) {
    eval { DateTime::Format::Natural->new(format => $format) };
    ok(!$@, "format $format");
}

my @bools = (
    [ 1,     '1'     ],
    [ 0,     '0'     ],
    [ true,  'true'  ],
    [ false, 'false' ],
);
foreach my $bool (@bools) {
    eval { DateTime::Format::Natural->new(prefer_future => $bool->[0]) };
    ok(!$@, "prefer_future $bool->[1]");
}

eval { DateTime::Format::Natural->new(time_zone => 'floating') };
ok(!$@, 'time_zone string');

eval { DateTime::Format::Natural->new(time_zone => DateTime::TimeZone->new(name => 'Europe/Zurich')) };
ok(!$@, 'time_zone object');

eval { DateTime::Format::Natural->new(daytime => {}) };
ok(!$@, 'daytime');

eval { DateTime::Format::Natural->new(datetime => DateTime->now) };
ok(!$@, 'datetime');
