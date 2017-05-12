use strict;
BEGIN { $^W = 1 }

use Test::More tests => 8;
use DateTime::Calendar::Julian;

#########################

sub test_dates {
    foreach my $test ( @_ )
    {
        my @args = @{ $test->[0] };
        my @results = @{ $test->[1] };

        my $dt = DateTime::Calendar::Julian->new(
                                year  => $args[0],
                                month => $args[1],
                                day   => $args[2],
                              );

        my ($year, $week) = $dt->week();

        is( "$year-W$week", "$results[0]-W$results[1]" );
    }
}

my @tests = ( [ [ 1749, 12, 31 ], [ 1749, 52 ] ],
              [ [ 1750,  1,  1 ], [ 1750,  1 ] ],
              [ [ 1750,  1,  7 ], [ 1750,  1 ] ],
              [ [ 1750,  1,  8 ], [ 1750,  2 ] ],
              [ [ 1750,  3, 26 ], [ 1750, 13 ] ],
              [ [ 1750, 12, 30 ], [ 1750, 52 ] ],
              [ [ 1750, 12, 31 ], [ 1751,  1 ] ],
              [ [ 1751,  1,  1 ], [ 1751,  1 ] ],
            );

test_dates( @tests );
