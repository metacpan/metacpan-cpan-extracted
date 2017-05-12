use strict;
use warnings;

use Test::More tests => 57;
use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;

# A very important day
my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
						      month => 3,
						      day => 25,
						      hour => 10,
						      minute => 15,
						  );

is($shire->year, 1419);
is($shire->is_leap_year, 0);

is($shire->month, 3);
is($shire->month_name, 'Rethe');
is( $shire->month_abbr(), 'Ret' );

is($shire->day, 25);
is($shire->mday, 25);
is($shire->day_of_month, 25);
is( $shire->day_0(), 24 );
is( $shire->mday_0(), 24 );
is( $shire->day_of_month_0(), 24 );

is($shire->wday, 2);
is($shire->dow, 2);
is($shire->day_of_week, 2);
is($shire->day_name, 'Sunday');
is($shire->day_abbr, 'Sun');

is($shire->holiday, 0);
is($shire->holiday_name, '');
is($shire->holiday_abbr, '');

is($shire->day_of_year, 86);
is($shire->doy, 86);

is($shire->week_year, 1419);
is($shire->week_number, 13);
is( $shire->weekday_of_month(), 4 );
is( $shire->week_of_month(), 4 );

is( $shire->quarter(), 1 );
is( $shire->quarter_0(), 0 );
is( $shire->quarter_name(), '1st quarter' );
is( $shire->quarter_abbr(), 'Q1' );
is( $shire->day_of_quarter(), 86 );
is( $shire->day_of_quarter_0(), 85 );

is( $shire->ymd(), '1419-03-25' );
is( $shire->dmy( '-' ), '25-03-1419' );
is( $shire->mdy( '/' ), '03/25/1419' );
is( $shire->date(), '1419-03-25' );
is( $shire->hms(), '10:15:00' );
is( $shire->time(), '10:15:00' );
is( $shire->iso8601(), '1419-03-25S10:15:00' );
is( $shire->datetime(), '1419-03-25S10:15:00' );

my $time = time;
my $shire2 = DateTime::Fiction::JRRTolkien::Shire->from_epoch(epoch => $time);
is($shire2->epoch, $time);
is(int($shire2->hires_epoch), $time);
# utc_rd_values and utc_rd_as_seconds were tested in the constructor tests

is( $shire->calendar_name(), 'Shire', q<Calendar name is 'Shire'> );

# Aliased to DateTime
is( $shire->time_zone()->name(), 'floating', q<Time zone is 'floating'> );
is( $shire->time_zone_long_name(),
    'floating', q<Time zone long name is 'floating'> );
is( $shire->time_zone_short_name(),
    'floating', q<Time zone short name is 'floating'> );

# Holidays

my $shire_h = DateTime::Fiction::JRRTolkien::Shire->new(
    year	=> 1419,
    holiday	=> 3,
);
is( $shire_h->holiday(), 3, q<Holiday number of Midyear's day> );
is( $shire_h->holiday_name(), q<Midyear's day>,
    q<Holiday name of Midyear's day> );
is( $shire_h->holiday_abbr(), q<Myd>,
    q<Holiday abbreviation of Midyear's day> );
is( $shire_h->week_number(), 0, q<Week number of Midyear's day> );

is( $shire_h->ymd( '/' ), '1419/Myd' );
is( $shire_h->dmy(), 'Myd-1419' );
is( $shire_h->mdy( '-' ), 'Myd-1419' );
is( $shire_h->date(), '1419-Myd' );
is( $shire_h->hms( '.' ), '00.00.00' );
is( $shire_h->time(), '00:00:00' );
is( $shire_h->iso8601(), '1419-MydS00:00:00' );
is( $shire_h->datetime(), '1419-MydS00:00:00' );

# ex: set textwidth=72 :
