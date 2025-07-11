#!/usr/bin/env perl

use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use Data::OFN::Thing;
use DateTime;

my $obj = Data::OFN::Thing->new(
        'iri' => 'https://www.spilberk.cz/',
        'invalidated' => Data::OFN::Common::TimeMoment->new(
                'date_and_time' => DateTime->new(
                        'day' => 27,
                        'month' => 11,
                        'year' => 2019,
                        'hour' => 9,
                        'time_zone' => '+02:00',
                ),
        ),
);

# Print out.
print 'IRI: '.$obj->iri."\n";
print 'Invalidated: '.$obj->invalidated->date_and_time."\n";

# Output:
# IRI: https://www.spilberk.cz/
# Invalidated: 2019-11-27T09:00:00