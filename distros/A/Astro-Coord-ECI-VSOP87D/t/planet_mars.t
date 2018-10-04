package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test;

use Astro::Coord::ECI::Utils qw{ rad2deg };
use Astro::Coord::ECI::VSOP87D::Mars;
use POSIX ();
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

my $mars = Astro::Coord::ECI::VSOP87D::Mars->new(
    station			=> washington_dc(),
);

my $time = timegm( 0, 0, 0, 1, 0, 2017 );

$mars->universal( $time );

note <<'EOD';

Conjunctions and elongations

Times from Guy Ottewell's Astronomical Calendar 2017 and 2018
http://www.universalworkshop.com/astronomical-calendar-2017/
http://www.universalworkshop.com/astronomical-calendar-2018/
He gives them to the nearest hour, so that is the accuracy of
my check.
EOD

( $time, my $quarter, my $desc ) = $mars->next_quarter();

note 'Conjunction';
is $quarter, 0, 'Event is conjunction';
is strftime_h( $time ), '2017-07-27 01', 'Time of conjunction';

( $time, $quarter, $desc ) = $mars->next_quarter();

note 'West quadrature';
is $quarter, 1, 'Event is west quadrature';
is strftime_h( $time ), '2018-03-24 16', 'Time of west quadrature';
# Ottewell JD 2458202.167

( $time, $quarter, $desc ) = $mars->next_quarter();

note 'Opposition';
is $quarter, 2, 'Event is opposition';
is strftime_h( $time ), '2018-07-27 05', 'Time of opposition';
# Ottewell JD 2458326.716

( $time, $quarter, $desc ) = $mars->next_quarter();

note 'East quadrature';
is $quarter, 3, 'Event is east quadrature';
is strftime_h( $time ), '2018-12-03 01', 'Timm of east quadrature';
# Ottewell JD 2458460.090

note 'Opposition -- explicit request';
$mars->universal(
    timegm( 0, 0, 0, 1, 0, 2017 ) );

( $time, $quarter, $desc ) = $mars->next_quarter( 2 );

note 'Opposition';
is $quarter, 2, 'Event is opposition';
is strftime_h( $time ), '2018-07-27 05', 'Time of opposition';


note <<'EOD';

Rise, meridian transit, and set in Washington, D.C. USA

Times are from the United States Naval Observatory
http://aa.usno.navy.mil/data/docs/mrst.php
This gives them to the nearest minute, so that is the accuracy
of my check. For portability the times are converted to UT.
EOD

note 'Rise';
$mars->universal(
    timegm( 0, 0, 4, 1, 3, 2018 ) );	# Midnight local.

( $time, my $rise ) = $mars->next_elevation();
is $rise, 1, 'Event is rise';
is strftime_m( $time ), '2018-04-01 06:24', 'Time of rise';

note 'Transit meridian';
( $time, $rise ) = $mars->next_meridian();
is $rise, 1, 'Event is meridian transit';
is strftime_m( $time ), '2018-04-01 11:05', 'Time of meridian transit';

note 'Set';
( $time, $rise ) = $mars->next_elevation();
is $rise, 0, 'Event is set';
is strftime_m( $time ), '2018-04-01 15:46', 'Time of set';

done_testing;

1;

# ex: set textwidth=72 :
