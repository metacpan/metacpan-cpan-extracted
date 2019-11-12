use strict;
use warnings;

use Test::More tests => 11;
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

        my $doy = $dt->day_of_year();

        is( $doy, $results[0], "doy of @args" );
    }
}

my @tests = ( [ [ 2003,  1,  1 ], [   1 ] ],
              [ [ 2003,  1, 31 ], [  31 ] ],
              [ [ 2003,  2, 28 ], [  59 ] ],
              [ [ 2003,  3,  1 ], [  60 ] ],
              [ [ 2003, 12, 31 ], [ 365 ] ],
              [ [ 1900,  1,  1 ], [   1 ] ],
              [ [ 1900,  1, 31 ], [  31 ] ],
              [ [ 1900,  2, 28 ], [  59 ] ],
              [ [ 1900,  2, 29 ], [  60 ] ],
              [ [ 1900,  3,  1 ], [  61 ] ],
              [ [ 1900, 12, 31 ], [ 366 ] ],
            );

test_dates( @tests );
