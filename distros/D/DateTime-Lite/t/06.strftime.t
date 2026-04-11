#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/06.strftime.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

my $dt = DateTime::Lite->new(
    year      => 2025,
    month     => 4,
    day       => 3,
    hour      => 14,
    minute    => 5,
    second    => 9,
    time_zone => 'UTC',
);

# NOTE: strftime basics
subtest 'strftime basics' => sub
{
    is( $dt->strftime( '%Y' ),    '2025',       '%Y' );
    is( $dt->strftime( '%m' ),    '04',         '%m' );
    is( $dt->strftime( '%d' ),    '03',         '%d' );
    is( $dt->strftime( '%H' ),    '14',         '%H' );
    is( $dt->strftime( '%M' ),    '05',         '%M' );
    is( $dt->strftime( '%S' ),    '09',         '%S' );
    is( $dt->strftime( '%Y-%m-%d' ), '2025-04-03', 'date pattern' );
    is( $dt->strftime( '%H:%M:%S' ), '14:05:09',   'time pattern' );
    is( $dt->strftime( '%F' ),    '2025-04-03', '%F (ISO date)' );
    is( $dt->strftime( '%T' ),    '14:05:09',   '%T (ISO time)' );
    is( $dt->strftime( '%%' ),    '%',          '%%' );
    is( $dt->strftime( '%n' ),    "\n",         '%n (newline)' );
    is( $dt->strftime( '%t' ),    "\t",         '%t (tab)' );
};

# NOTE: 12-hour clock
subtest '12-hour clock' => sub
{
    is( $dt->strftime( '%I' ), '02', '%I (12h hour)' );
    is( $dt->strftime( '%p' ), 'PM', '%p (AM/PM)' );
};

my $morning = DateTime::Lite->new(
    year      => 2025,
    month     => 4,
    day       => 3,
    hour      => 9,
    minute    => 0,
    second    => 0,
    time_zone => 'UTC',
);
is( $morning->strftime( '%p' ), 'AM', '%p AM for morning' );
is( $morning->strftime( '%I' ), '09', '%I for 9am' );

# NOTE: Day / month names (locale-dependent, just check non-empty)
subtest 'Day / month names (locale-dependent, just check non-empty)' => sub
{
    my $day_name = $dt->strftime( '%A' );
    ok( defined( $day_name ) && length( $day_name ) > 0, '%A (day name) is non-empty' );
    
    my $month_name = $dt->strftime( '%B' );
    ok( defined( $month_name ) && length( $month_name ) > 0, '%B (month name) is non-empty' );
};

# NOTE: Day-of-year / week / day-of-week
subtest 'Day-of-year / week / day-of-week' => sub
{
    is( $dt->strftime( '%j' ), '093', '%j (day of year)' );
    is( $dt->strftime( '%u' ), '4',   '%u (day of week, ISO: Thu=4)' );
    is( $dt->strftime( '%V' ), '14',  '%V (ISO week number)' );
};

# NOTE: %s (epoch)
subtest '%s (epoch)' => sub
{
    my $epoch = $dt->strftime( '%s' );
    ok( $epoch =~ /^\d+$/, '%s returns a number' );
    is( $epoch, $dt->epoch, '%s matches ->epoch' );
};

# NOTE: format_cldr
subtest 'format_cldr' => sub
{
    is( $dt->format_cldr( 'yyyy' ),    '2025', 'CLDR: yyyy' );
    is( $dt->format_cldr( 'MM' ),      '04',   'CLDR: MM' );
    is( $dt->format_cldr( 'dd' ),      '03',   'CLDR: dd' );
    is( $dt->format_cldr( 'HH' ),      '14',   'CLDR: HH' );
    is( $dt->format_cldr( 'mm' ),      '05',   'CLDR: mm' );
    is( $dt->format_cldr( 'ss' ),      '09',   'CLDR: ss' );
    is( $dt->format_cldr( "yyyy-MM-dd'T'HH:mm:ss" ), '2025-04-03T14:05:09', 'CLDR: full ISO pattern' );
};

# NOTE: format_cldr - quoted literals
subtest 'format_cldr - quoted literals' => sub
{
    is( $dt->format_cldr( "'Today is' yyyy-MM-dd" ), 'Today is 2025-04-03', 'CLDR: quoted literal prefix' );
};

done_testing;

__END__
