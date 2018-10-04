package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test;

use Astro::Coord::ECI::Utils qw{ rad2deg };
use Astro::Coord::ECI::VSOP87D::Sun;
use POSIX ();
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

my $sun = Astro::Coord::ECI::VSOP87D::Sun->new(
    station			=> washington_dc(),
);

my $time = timegm( 0, 0, 0, 1, 0, 2018 );

$sun->universal( $time );

( $time, my $quarter, my $desc ) = $sun->next_quarter();

note <<'EOD';

Equinoxes and solstices

Times are from the United States Naval Observatory
http://aa.usno.navy.mil/data/docs/EarthSeasons.php
This gives them to the nearest minute, so that is the accuracy
of my check. For portability the times are converted to UT.
EOD

note 'March equinox';
is $quarter, 0, 'Event is March equinox';
is strftime_m( $time ), '2018-03-20 16:15', 'Timm of March equinox';

( $time, $quarter, $desc ) = $sun->next_quarter();

note 'June solstice';
is $quarter, 1, 'Event is June solstice';
is strftime_m( $time ), '2018-06-21 10:07', 'Time of June solstice';

( $time, $quarter, $desc ) = $sun->next_quarter();

note 'September equinox';
is $quarter, 2, 'Event is September equinox';
is strftime_m( $time ), '2018-09-23 01:54', 'Time of September equinox';

( $time, $quarter, $desc ) = $sun->next_quarter();

note 'December solstice';
is $quarter, 3, 'Event is December solstice';
is strftime_m( $time ), '2018-12-21 22:22', 'Time of December solstice';
# TODO: USNO gets 22:23 -- I get 22:22:18

note 'June solstice -- explicit request';
$sun->universal(
    timegm( 0, 0, 0, 1, 0, 2018 ) );

( $time, $quarter, $desc ) = $sun->next_quarter( 1 );

is $quarter, 1, 'Event is June solstice';
is strftime_m( $time ), '2018-06-21 10:07', 'Time of June solstice';

note <<'EOD';

Rise, meridian transit, and set in Washington, D.C. USA

Times are from the United States Naval Observatory
http://aa.usno.navy.mil/data/docs/mrst.php
This gives them to the nearest minute, so that is the accuracy
of my check. For portability the times are converted to UT.
EOD

note 'Rise';
$sun->universal(
    timegm( 0, 0, 4, 1, 3, 2018 ) );	# Midnight local.

( $time, my $rise ) = $sun->next_elevation();
is $rise, 1, 'Event is rise';
is strftime_m( $time ), '2018-04-01 10:53', 'Time of rise';

( $time, $rise ) = $sun->next_meridian();
is $rise, 1, 'Event is meridian transit';
is strftime_m( $time ), '2018-04-01 17:12', 'Time of meridian transit';

( $time, $rise ) = $sun->next_elevation();
is $rise, 0, 'Event is set';
is strftime_m( $time ), '2018-04-01 23:32', 'Time of set';

done_testing;

1;

# ex: set textwidth=72 :
