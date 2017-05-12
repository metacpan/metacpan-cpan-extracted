use strict;
BEGIN { $^W = 1 }

use Test::More tests => 34;
use DateTime::Calendar::Pataphysical;

#########################

my $d = DateTime::Calendar::Pataphysical
            ->new( year => 130, month => 10, day => 9 );
my $d2 = DateTime::Calendar::Pataphysical
            ->new( year => 130, month => 10, day => 29 );
my $d3 = DateTime::Calendar::Pataphysical
            ->new( year => 130, month => 11, day => 29 );
my $d4 = DateTime::Calendar::Pataphysical
            ->new( year => 130, month => 11, day => 15 );

is( $d->month_0,  9, 'month_0' );
is( $d->day_0  ,  8, 'day_0' );

is( $d->month_name, 'Merdre', 'month_name' );
is( $d2->month_name, 'Merdre', 'month_name (hunyadi)' );
is( $d3->month_name, 'Gidouille', 'month_name (hunyadi gras)' );

is( $d->day_of_week, 2, 'day_of_week (monday)' );
is( $d4->day_of_week, 1, 'day_of_week (sunday)' );
ok( !defined $d2->day_of_week, 'day_of_week (hunyadi)' );
ok( !defined $d3->day_of_week, 'day_of_week (hunyadi gras)' );

is( $d->day_of_week_0, 1, 'day_of_week (monday)' );
is( $d4->day_of_week_0, 0, 'day_of_week (sunday)' );
ok( !defined $d2->day_of_week_0, 'day_of_week (hunyadi)' );

is( $d->week, 38, 'week' );
ok( !defined $d2->week, 'week (hunyadi)' );
ok( !defined $d3->week, 'week (hunyadi gras)' );

is( $d->day_of_year, 270, 'day_of_year' );
is( $d2->day_of_year, 290, 'day_of_year (hunyadi)' );
is( $d3->day_of_year, 319, 'day_of_year (hunyadi gras)' );

is( $d->day_of_year_0, 269, 'day_of_year' );

is( $d->ymd('.'), '130.10.09', 'ymd' );
is( $d2->ymd, '130-10-29', 'ymd (hunyadi)' );
is( $d->mdy('.'), '10.09.130', 'mdy' );
is( $d2->mdy, '10-29-130', 'ymd (hunyadi)' );
is( $d->dmy('.'), '09.10.130', 'dmy' );
is( $d2->dmy, '29-10-130', 'ymd (hunyadi)' );

is( $d->datetime, '130-10-09EP', 'ymd' );

is($d->feast, 'Vidange', 'feast Vidange');
is($d->type_of_feast, 'v');

is($d2->feast, 'Défaite du Mufle', 'feast Défaite du Mufle');
is($d2->type_of_feast, 'v');

is($d3->feast, "Nom d'Ubu", "feast Nom d'Ubu");
is($d3->type_of_feast, '2');

is($d4->feast, 'Ste Giborgne, vénérable', 'feast Sainte Giborgne, vénérable');
is($d4->type_of_feast, '3');
