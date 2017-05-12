
# set up strictures
use strict;
use warnings;

# set up tests
my @tests;
BEGIN {

    # some initializations
    my $second=  1;
    my $minute= 60 * $second;
    my $hour=   60 * $minute;
    my $day=    24 * $hour;
    my $week=    7 * $day;

    # set up
    @tests= (
 [ undef, undef ],
 [ 'foo', undef ],
 [    1, 1 * $second ],
 [ '0s', 0 * $second ],
 [ '2s', 2 * $second ],
 [ '3S', 3 * $second ],
 [ '0m', 0 * $minute ],
 [ '4m', 4 * $minute ],
 [ '5M', 5 * $minute ],
 [ '0h', 0 * $hour   ],
 [ '6h', 6 * $hour   ],
 [ '7H', 7 * $hour   ],
 [ '0d', 0 * $day    ],
 [ '8d', 8 * $day    ],
 [ '9D', 9 * $day    ],
 [ '0w', 0 * $week   ],
 [ '1w', 1 * $week   ],
 [ '2W', 2 * $week   ],
 [ '3W4d5H6m7S', 3 * $week + 4 * $day + 5 * $hour + 6 * $minute + 7 * $second ],
    );
} #BEGIN

# Set up tests
use Test::More tests => scalar(@tests);

# get the stuff we need
use Cache::Memcached::Managed;
*e2s= \&Cache::Memcached::Managed::_expiration2seconds;

# do the tests!
foreach (@tests) {
    my ( $expiration, $seconds )= @{$_};

    # expecting undef result
    if ( !defined $seconds ) {
        ok( !defined( e2s( undef, $expiration ) ),
          "checking " . ( defined $expiration ? $expiration : 'undef' ) );
    }

    # expecting real result
    else {
        is( e2s( undef, $expiration ), $seconds, "checking $expiration" );
    }
}
