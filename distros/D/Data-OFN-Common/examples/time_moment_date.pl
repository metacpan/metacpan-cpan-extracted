#!/usr/bin/env perl

use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use DateTime;

my $obj = Data::OFN::Common::TimeMoment->new(
        'date' => DateTime->new(
                'day' => 8,
                'month' => 7,
                'year' => 2025,
        ),
);

print 'Date: '.$obj->date."\n";

# Output:
# Date: 2025-07-08T00:00:00