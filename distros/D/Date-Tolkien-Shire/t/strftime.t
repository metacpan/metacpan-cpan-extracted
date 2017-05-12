package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire;
use Test::More 0.47;	# The best we can do with 5.6.2.
use Time::Local;

plan tests => 3;

foreach (
    [ 2010, 6, 21, '%Ex%n%Ed', <<'EOD' ],
Mersday 30 Forelithe 7474
EOD
    [ 2010, 6, 22, '%Ex%n%Ed', <<'EOD' ],
Highday 1 Lithe 7474
EOD
    [ 2010, 6, 23, '%Ex%n%Ed', <<'EOD' ],
Midyear's day 7474
Wedding of King Elessar and Arwen, 1419.
EOD
) {
    my ( $year, $month, $day, $fmt, $want ) = @{ $_ };
    my $dts = Date::Tolkien::Shire->new(
	timelocal( 0, 0, 0, $day, $month - 1, $year ) );
    my $date = sprintf '%04d-%02d-%02d', $year, $month, $day;
    is( scalar $dts->strftime( $fmt ), $want, "$date formatted with '$fmt'" );
}

1;

# ex: set textwidth=72 :
