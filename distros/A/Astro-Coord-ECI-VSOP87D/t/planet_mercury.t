package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test;

use Astro::Coord::ECI::Utils qw{ rad2deg };
use Astro::Coord::ECI::VSOP87D::Mercury;
use POSIX ();
use Test::More 0.88;	# Because of done_testing();
use Time::Local qw{ timegm };

my $mercury = Astro::Coord::ECI::VSOP87D::Mercury->new(
    elongation_in_longitude	=> 0,
    station			=> washington_dc(),
);

my $time = timegm( 0, 0, 0, 1, 0, 2018 );

$mercury->universal( $time );

( $time, my $quarter, my $desc ) = $mercury->next_quarter();

note <<'EOD';

Conjunctions and elongations

Times from Guy Ottewell's Astronomical Calendar 2018
http://www.universalworkshop.com/astronomical-calendar-2018/
He gives them to the nearest hour, so that is the accuracy of
my check.
EOD

note 'Elongation west';
is $quarter, 3, 'Event is elongation west';
is strftime_h( $time ), '2018-01-01 20', 'Timm of elongation west';
is sprintf( '%.1f', rad2deg( $mercury->__angle_subtended_from_earth() )
    ), '-22.7', 'Angle of elongation west';
# TODO Ottewell has 22.6

( $time, $quarter, $desc ) = $mercury->next_quarter();

note 'Superior conjunction';
is $quarter, 0, 'Event is superior conjunction';
is strftime_h( $time ), '2018-02-17 12', 'Time of superior conjunction';

( $time, $quarter, $desc ) = $mercury->next_quarter();

note 'Elongation east';
is $quarter, 1, 'Event is elongation east';
is strftime_h( $time ), '2018-03-15 15', 'Time of elongation east';
is sprintf( '%.1f', rad2deg( $mercury->__angle_subtended_from_earth() )
    ), '18.4', 'Angle of elongation east';

( $time, $quarter, $desc ) = $mercury->next_quarter();

note 'Inferior conjunction';
is $quarter, 2, 'Event is inferior conjunction';
is strftime_h( $time ), '2018-04-01 18', 'Time of inferior conjunction';

note 'Superior conjunction -- explicit request';
$mercury->universal(
    timegm( 0, 0, 0, 1, 0, 2018 ) );

( $time, $quarter, $desc ) = $mercury->next_quarter( 0 );

is $quarter, 0, 'Event is superior conjunction';
is strftime_h( $time ), '2018-02-17 12', 'Time of superior conjunction';

note <<'EOD';

Rise, meridian transit, and set in Washington, D.C. USA

Times are from the United States Naval Observatory
http://aa.usno.navy.mil/data/docs/mrst.php
This gives them to the nearest minute, so that is the accuracy
of my check. For portability the times are converted to UT.
EOD

note 'Rise';
$mercury->universal(
    timegm( 0, 0, 4, 1, 3, 2018 ) );	# Midnight local.

( $time, my $rise ) = $mercury->next_elevation();
is $rise, 1, 'Event is rise';
is strftime_m( $time ), '2018-04-01 10:42', 'Time of rise';

( $time, $rise ) = $mercury->next_meridian();
is $rise, 1, 'Event is meridian transit';
is strftime_m( $time ), '2018-04-01 17:08', 'Time of meridian transit';

( $time, $rise ) = $mercury->next_elevation();
is $rise, 0, 'Event is set';
is strftime_m( $time ), '2018-04-01 23:32', 'Time of set';

done_testing;

1;

# ex: set textwidth=72 :
