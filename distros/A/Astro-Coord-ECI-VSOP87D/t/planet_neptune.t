package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test;

use Astro::Coord::ECI::Utils qw{ rad2deg };
use Astro::Coord::ECI::VSOP87D::Neptune;
use POSIX ();
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

my $uranus = Astro::Coord::ECI::VSOP87D::Neptune->new(
    station			=> washington_dc(),
);

my $time = timegm( 0, 0, 0, 1, 0, 2018 );

$uranus->universal( $time );

note <<'EOD';

Conjunctions and elongations

Times from Guy Ottewell's Astronomical Calendar 2018
http://www.universalworkshop.com/astronomical-calendar-2018/
He gives them to the nearest hour, so that is the accuracy of
my check.
EOD

( $time, my $quarter, my $desc ) = $uranus->next_quarter();

note 'Conjunction';
is $quarter, 0, 'Event is conjunction';
is strftime_h( $time ), '2018-03-04 14', 'Time of conjunction';
# Ottewell JD 2458182.081

( $time, $quarter, $desc ) = $uranus->next_quarter();

note 'West quadrature';
is $quarter, 1, 'Event is west quadrature';
is strftime_h( $time ), '2018-06-07 06', 'Time of west quadrature';
# Taken on faith -- not reported by Ottewell

( $time, $quarter, $desc ) = $uranus->next_quarter();

note 'Opposition';
is $quarter, 2, 'Event is opposition';
is strftime_h( $time ), '2018-09-07 18', 'Time of opposition';
# Ottewell JD 2458369.260

( $time, $quarter, $desc ) = $uranus->next_quarter();

note 'East quadrature';
is $quarter, 3, 'Event is east quadrature';
is strftime_h( $time ), '2018-12-05 22', 'Timm of east quadrature';
# Taken on faith -- not reported by Ottewell

note 'Opposition -- explicit request';
$uranus->universal(
    timegm( 0, 0, 0, 1, 0, 2018 ) );
( $time, $quarter, $desc ) = $uranus->next_quarter( 2 );
is $quarter, 2, 'Event is opposition';
is strftime_h( $time ), '2018-09-07 18', 'Time of opposition';
# Ottewell JD 2458369.260


note <<'EOD';

Rise, meridian transit, and set in Washington, D.C. USA

Times are from the United States Naval Observatory
http://aa.usno.navy.mil/data/docs/mrst.php
This gives them to the nearest minute, so that is the accuracy
of my check. For portability the times are converted to UT.
EOD

$uranus->universal(
    timegm( 0, 0, 4, 1, 3, 2018 ) );	# Midnight local.

note 'Rise';
( $time, my $rise ) = $uranus->next_elevation();
is $rise, 1, 'Event is rise';
is strftime_m( $time ), '2018-04-01 09:54', 'Time of rise';

note 'Transit meridian';
( $time, $rise ) = $uranus->next_meridian();
is $rise, 1, 'Event is meridian transit';
is strftime_m( $time ), '2018-04-01 15:34', 'Time of meridian transit';

note 'Set';
( $time, $rise ) = $uranus->next_elevation();
is $rise, 0, 'Event is set';
is strftime_m( $time ), '2018-04-01 21:15', 'Time of set';
# USNO has 21:14

done_testing;

1;

# ex: set textwidth=72 :
