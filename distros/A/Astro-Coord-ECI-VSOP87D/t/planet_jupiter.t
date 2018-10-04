package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test;

use Astro::Coord::ECI::Utils qw{ rad2deg };
use Astro::Coord::ECI::VSOP87D::Jupiter;
use POSIX ();
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

my $jupiter = Astro::Coord::ECI::VSOP87D::Jupiter->new(
    station			=> washington_dc(),
);

my $time = timegm( 0, 0, 0, 1, 0, 2018 );

$jupiter->universal( $time );

note <<'EOD';

Conjunctions and elongations

Times from Guy Ottewell's Astronomical Calendar 2018
http://www.universalworkshop.com/astronomical-calendar-2018/
He gives them to the nearest hour, so that is the accuracy of
my check.
EOD

( $time, my $quarter, my $desc ) = $jupiter->next_quarter();

note 'West quadrature';
is $quarter, 1, 'Event is west quadrature';
is strftime_h( $time ), '2018-02-10 23', 'Time of west quadrature';
# Ottewell JD 2458160.471

( $time, $quarter, $desc ) = $jupiter->next_quarter();

note 'Opposition';
is $quarter, 2, 'Event is opposition';
is strftime_h( $time ), '2018-05-09 01', 'Time of opposition';
# Ottewell JD 2458247.520, which equates to 2018-05-09 00:28:48
# I got 2018-05-09 00:39:03

( $time, $quarter, $desc ) = $jupiter->next_quarter();

note 'East quadrature';
is $quarter, 3, 'Event is east quadrature';
is strftime_h( $time ), '2018-08-06 23', 'Timm of east quadrature';
# Ottewell JD 2458337.475

( $time, $quarter, $desc ) = $jupiter->next_quarter();

note 'Conjunction';
is $quarter, 0, 'Event is conjunction';
is strftime_h( $time ), '2018-11-26 07', 'Time of conjunction';
# Ottewell JD 2458448.778

note 'Opposition -- explicit request';
$jupiter->universal(
    timegm( 0, 0, 0, 1, 0, 2018 ) );
( $time, $quarter, $desc ) = $jupiter->next_quarter( 2 );
is $quarter, 2, 'Event is opposition';
is strftime_h( $time ), '2018-05-09 01', 'Time of opposition';
# Ottewell JD 2458247.520, which equates to 2018-05-09 00:28:48
# I got 2018-05-09 00:39:03


note <<'EOD';

Rise, meridian transit, and set in Washington, D.C. USA

Times are from the United States Naval Observatory
http://aa.usno.navy.mil/data/docs/mrst.php
This gives them to the nearest minute, so that is the accuracy
of my check. For portability the times are converted to UT.
EOD

$jupiter->universal(
    timegm( 0, 0, 4, 1, 3, 2018 ) );	# Midnight local.
					# Jupiter is already risen at
					# this point

note 'Transit meridian';
( $time, my $rise ) = $jupiter->next_meridian();
is $rise, 1, 'Event is meridian transit';
is strftime_m( $time ), '2018-04-01 07:51', 'Time of meridian transit';

note 'Set';
( $time, $rise ) = $jupiter->next_elevation();
is $rise, 0, 'Event is set';
is strftime_m( $time ), '2018-04-01 12:56', 'Time of set';

note 'Rise';
( $time, $rise ) = $jupiter->next_elevation();
is $rise, 1, 'Event is rise';
is strftime_m( $time ), '2018-04-02 02:42', 'Time of rise';

done_testing;

1;

# ex: set textwidth=72 :
