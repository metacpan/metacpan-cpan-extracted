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

# NOTE: format_cldr: quoted literals
subtest 'format_cldr: quoted literals' => sub
{
    is( $dt->format_cldr( "'Today is' yyyy-MM-dd" ), 'Today is 2025-04-03', 'CLDR: quoted literal prefix' );
};

# NOTE: strftime - complete token coverage
# Reference datetime: Wednesday 15 July 2026, 14:30:45.123456789 BST (UTC+01:00)
# Using Europe/London in summer so %Z = BST, %z = +0100, %:z = +01:00
my $ref = DateTime::Lite->new(
    year       => 2026,
    month      => 7,
    day        => 15,
    hour       => 14,
    minute     => 30,
    second     => 45,
    nanosecond => 123456789,
    time_zone  => 'Europe/London',
    locale     => 'en-GB',
);

# NOTE: 12-hour clock
subtest 'strftime: weekday tokens' => sub
{
    is( $ref->strftime( '%a' ), 'Wed',       '%a (abbreviated weekday)' );
    is( $ref->strftime( '%A' ), 'Wednesday', '%A (full weekday)' );
    is( $ref->strftime( '%E' ), 'Wed',       '%E (alias for %a)' );
    is( $ref->strftime( '%u' ), '3',         '%u (Mon=1, Wed=3)' );
    is( $ref->strftime( '%w' ), '3',         '%w (Sun=0, Wed=3)' );
};

# NOTE: strftime: month tokens
subtest 'strftime: month tokens' => sub
{
    is( $ref->strftime( '%b' ), 'Jul',  '%b (abbreviated month)' );
    is( $ref->strftime( '%B' ), 'July', '%B (full month)' );
    is( $ref->strftime( '%h' ), 'Jul',  '%h (alias for %b)' );
    is( $ref->strftime( '%m' ), '07',   '%m (numeric month)' );
};

# NOTE: strftime: date tokens
subtest 'strftime: date tokens' => sub
{
    is( $ref->strftime( '%Y' ), '2026',       '%Y (4-digit year)' );
    is( $ref->strftime( '%y' ), '26',         '%y (2-digit year)' );
    is( $ref->strftime( '%C' ), '20',         '%C (century)' );
    is( $ref->strftime( '%d' ), '15',         '%d (day of month, zero-padded)' );
    is( $ref->strftime( '%e' ), '15',         '%e (day of month, space-padded)' );
    is( $ref->strftime( '%j' ), '196',        '%j (day of year)' );
    is( $ref->strftime( '%F' ), '2026-07-15', '%F (ISO date)' );
    is( $ref->strftime( '%D' ), '07/15/26',   '%D (%m/%d/%y)' );
    is( $ref->strftime( '%G' ), '2026',       '%G (ISO week year)' );
    is( $ref->strftime( '%g' ), '26',         '%g (ISO week year, 2-digit)' );
    is( $ref->strftime( '%V' ), '29',         '%V (ISO week number)' );
    is( $ref->strftime( '%U' ), '28',         '%U (week number, Sun-based)' );
    is( $ref->strftime( '%W' ), '28',         '%W (week number, Mon-based)' );
};

# NOTE: strftime: time tokens
subtest 'strftime: time tokens' => sub
{
    is( $ref->strftime( '%H' ), '14',       '%H (24h hour)' );
    is( $ref->strftime( '%I' ), '02',       '%I (12h hour)' );
    is( $ref->strftime( '%k' ), '14',       '%k (24h hour, space-padded)' );
    is( $ref->strftime( '%l' ), ' 2',       '%l (12h hour, space-padded)' );
    is( $ref->strftime( '%M' ), '30',       '%M (minute)' );
    is( $ref->strftime( '%S' ), '45',       '%S (second)' );
    like( $ref->strftime( '%p' ), qr/^pm$/i, '%p (AM/PM, case varies by locale)' );
    is( $ref->strftime( '%P' ), 'pm',       '%P (am/pm lowercase)' );
    is( $ref->strftime( '%T' ), '14:30:45', '%T (%H:%M:%S)' );
    is( $ref->strftime( '%R' ), '14:30',    '%R (%H:%M)' );
    like( $ref->strftime( '%r' ), qr/02:30:45 pm/i, '%r (12h time, case varies by locale)' );
};

# NOTE: strftime: nanosecond tokens
subtest 'strftime: nanosecond tokens' => sub
{
    is( $ref->strftime( '%3N' ),  '123',         '%3N (milliseconds)' );
    is( $ref->strftime( '%6N' ),  '123456',       '%6N (microseconds)' );
    is( $ref->strftime( '%9N' ),  '123456789',    '%9N (nanoseconds)' );
};

# NOTE: strftime: timezone tokens
subtest 'strftime: timezone tokens' => sub
{
    is( $ref->strftime( '%Z' ),  'BST',           '%Z (timezone short name)' );
    is( $ref->strftime( '%z' ),  '+0100',         '%z (UTC offset, no colon)' );
    is( $ref->strftime( '%:z' ), '+01:00',        '%:z (UTC offset, with colon)' );
    is( $ref->strftime( '%O' ),  'Europe/London', '%O (IANA timezone name)' );
};

# NOTE: strftime: composite and special tokens
subtest 'strftime: composite and special tokens' => sub
{
    is( $ref->strftime( '%s' ),  '1784122245',        '%s (epoch seconds)' );
    is( $ref->strftime( '%%' ),  '%',                 '%% (literal percent)' );
    is( $ref->strftime( '%n' ),  "\n",              '%n (newline)' );
    is( $ref->strftime( '%t' ),  "\t",              '%t (tab)' );
    is( $ref->strftime( '%F %T.%9N %Z (%:z)' ),
        '2026-07-15 14:30:45.123456789 BST (+01:00)',
        'composite pattern with %:z' );
    is( $ref->strftime( '%A %d %B %Y, %T.%N %Z (UTC%:z)' ),
        'Wednesday 15 July 2026, 14:30:45.123456789 BST (UTC+01:00)',
        'full reference pattern' );
};

# NOTE: strftime: method interpolation
subtest 'strftime: method interpolation' => sub
{
    is( $ref->strftime( '%{quarter}' ),     '3',   '%{quarter}' );
    is( $ref->strftime( '%{day_of_year}' ), '196', '%{day_of_year}' );
    is( $ref->strftime( '%{week_number}' ), '29',  '%{week_number}' );
};

done_testing;

__END__
