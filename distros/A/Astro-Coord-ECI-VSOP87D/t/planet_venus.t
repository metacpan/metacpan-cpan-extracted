package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test;

use Astro::Coord::ECI::Utils qw{ rad2deg };
use Astro::Coord::ECI::VSOP87D::Venus;
use POSIX ();
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

my $venus = Astro::Coord::ECI::VSOP87D::Venus->new(
    elongation_in_longitude	=> 0,
    station			=> washington_dc(),
);

my $time = timegm( 0, 0, 0, 1, 0, 2017 );

$venus->universal( $time );

note <<'EOD';

Conjunctions and elongations

Times from Guy Ottewell's Astronomical Calendar 2017 and 2018
http://www.universalworkshop.com/astronomical-calendar-2017/
http://www.universalworkshop.com/astronomical-calendar-2018/
He gives them to the nearest hour, so that is the accuracy of
my check.
EOD

( $time, my $quarter, my $desc ) = $venus->next_quarter();

note 'Elongation east';
is $quarter, 1, 'Event is elongation east';
is strftime_h( $time ), '2017-01-12 13', 'Time of elongation east';
is sprintf( '%.1f', rad2deg( $venus->__angle_subtended_from_earth() )
    ), '47.1', 'Angle of elongation east';
# TODO Ottewell got 47.2

( $time, $quarter, $desc ) = $venus->next_quarter();

note 'Inferior conjunction';
is $quarter, 2, 'Event is inferior conjunction';
is strftime_h( $time ), '2017-03-25 10', 'Time of inferior conjunction';

( $time, $quarter, $desc ) = $venus->next_quarter();

note 'Elongation west';
is $quarter, 3, 'Event is elongation west';
is strftime_h( $time ), '2017-06-03 13', 'Timm of elongation west';
is sprintf( '%.1f', rad2deg( $venus->__angle_subtended_from_earth() )
    ), '-45.9', 'Angle of elongation west';
# TODO Ottewell got 12. I got 13 - well, 12:30:34

( $time, $quarter, $desc ) = $venus->next_quarter();

note 'Superior conjunction';
is $quarter, 0, 'Event is superior conjunction';
is strftime_h( $time ), '2018-01-09 07', 'Time of superior conjunction';
# TODO Ottewell got 06 (well, JD 2458127.852 = 06:20:09. I get 07:00:55)

note 'Superior conjunction -- explicit request';
$venus->universal(
    timegm( 0, 0, 0, 1, 0, 2017 ) );

( $time, $quarter, $desc ) = $venus->next_quarter( 0 );

is $quarter, 0, 'Event is superior conjunction';
is strftime_h( $time ), '2018-01-09 07', 'Time of superior conjunction';
# TODO Ottewell got 06 (well, JD 2458127.852 = 06:20:09. I get 07:00:55)

note <<'EOD';

Rise, meridian transit, and set in Washington, D.C. USA

Times are from the United States Naval Observatory
http://aa.usno.navy.mil/data/docs/mrst.php
This gives them to the nearest minute, so that is the accuracy
of my check. For portability the times are converted to UT.
EOD

note 'Rise';
$venus->universal(
    timegm( 0, 0, 4, 1, 3, 2018 ) );	# Midnight local.

( $time, my $rise ) = $venus->next_elevation();
is $rise, 1, 'Event is rise';
is strftime_m( $time ), '2018-04-01 11:46', 'Time of rise';

( $time, $rise ) = $venus->next_meridian();
is $rise, 1, 'Event is meridian transit';
is strftime_m( $time ), '2018-04-01 18:28', 'Time of meridian transit';

( $time, $rise ) = $venus->next_elevation();
is $rise, 0, 'Event is set';
is strftime_m( $time ), '2018-04-02 01:10', 'Time of set';

done_testing;

1;

# ex: set textwidth=72 :
