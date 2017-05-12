use strict;
BEGIN { $^W = 1 }

use Test::MockTime qw( set_absolute_time );
use Test::More tests => 9;
use DateTime::Calendar::Pataphysical;

#########################

my $d = DateTime::Calendar::Pataphysical->new(
            year => 130, month => 7, day => 1 );

is( $d->day_name, 'dimanche', 'French week name' );

$d = DateTime::Calendar::Pataphysical->new(
            year => 130, month => 7, day => 4, locale => 'English' );

is( $d->day_name, 'Wednesday', 'English week name' );

$d->set( locale => 'French' );

my $l = DateTime::Locale->load( 'Dutch' );
$d->set( locale => $l );
is( $d->day_name, 'woensdag', 'Dutch week name' );

$d = DateTime::Calendar::Pataphysical->new(
            year => 130, month => 7, day => 29, locale => $l );
is( $d->day_name, 'hunyadi', 'Dutch name hunyadi' );

$d->set( locale => 'English' );
is( $d->day_name, 'Hunyadi', 'English name Hunyadi' );

$d = DateTime::Calendar::Pataphysical->from_epoch( epoch => 0,
                                                   locale => 'English' );
is( $d->day_name, 'Wednesday', 'from_epoch() accepts locale' );

set_absolute_time(0);
$d = DateTime::Calendar::Pataphysical->now( locale => 'Dutch' );
is( $d->day_name, 'woensdag', 'now() accepts locale' );

$d = DateTime::Calendar::Pataphysical->from_object( object => $d,
                                                    locale => 'English' );
is( $d->day_name, 'Wednesday', 'from_object() accepts locale' );

$d = DateTime::Calendar::Pataphysical->last_day_of_month(
            year => 130, month => 1, locale => 'Dutch' );
is( $d->day_name, 'hunyadi', 'last_day_of_month() accepts locale' );
