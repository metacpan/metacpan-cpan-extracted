#!/usr/bin/env perl

use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use DateTime;

my $obj = Data::OFN::Common::TimeMoment->new(
        'date_and_time' => DateTime->new(
                'day' => 8,
                'month' => 7,
                'year' => 2025,
                'hour' => 12,
                'minute' => 10,
        ),
);

print 'Date and time: '.$obj->date_and_time."\n";

# Output:
# Date and time: 2025-07-08T12:10:00