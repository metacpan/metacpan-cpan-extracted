package main;

use 5.006002;

use strict;
use warnings;

use Astro::Coord::ECI::Utils ();
use Test::More 0.88;	# Because of done_testing();

use Time::Local qw{ timegm };

# Encapsulation violation. Do not do this at home.
*ya = Astro::Coord::ECI::Utils->can( '_year_adjust_y2038' );

note <<'EOD';

Round-trip check of _year_adjust_y2038(), to ensure that, if we use the
Time::y2038 versions of timegm() and gmtime() (both of which deal in
Perl years) _year_adjust_y2038() -> timegm() -> gmtime() gives the same
year back as if we use the Time::Local version of timegm() (which is
just weird).

It turns out that Time::y2038 is not actually needed for this; all we
need is to ensure that the year computed by _year_adjust_y2038() is
equal to the year we get using the core gmtime() and the Time::Local
timegm().

EOD

foreach my $year ( -4900 .. 1099 ) {	# -3000 to 2999, Perl years
    my $got = ya( $year );
    my $want = ( gmtime timegm( 0, 0, 0, 1, 0, $year ) )[5];
    cmp_ok $got, '==', $want, "_year_adjust_y2038( $year )";
}

done_testing;

1;

# ex: set textwidth=72 :
