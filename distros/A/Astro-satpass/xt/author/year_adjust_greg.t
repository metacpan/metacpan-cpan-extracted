package main;

use 5.006002;

use strict;
use warnings;

use Astro::Coord::ECI::Utils ();
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

# Encapsulation violation. Do not do this at home.
*yag = Astro::Coord::ECI::Utils->can( '_year_adjust_greg' );

note <<'EOD';

Round-trip check of _year_adjust_greg(), to ensure that the chain
_year_adjust_greg() -> timegm() -> gmtime() gives the same year back
(after adding 1900 to the year gmtime() generates, of course).

EOD

foreach my $year ( -3000 .. 2999 ) {
    my $got = ( gmtime timegm( 0, 0, 0, 1, 0, yag( $year ) ) )[5] + 1900;
    cmp_ok $got, '==', $year, "_year_adjust_greg( $year )";
}

done_testing;

1;

# ex: set textwidth=72 :
