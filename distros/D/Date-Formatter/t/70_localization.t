use Test::More tests => 2;

use strict;
use warnings;

use_ok( 'Date::Formatter' );

my $date = Date::Formatter->now( locale => 'fr_ca' );

my $day_of_week = $date->getDayOfWeek;
like( $day_of_week, qr/dimanche|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche/ );
