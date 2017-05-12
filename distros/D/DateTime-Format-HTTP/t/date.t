#!/usr/bin/perl -w
use strict;
use lib 'inc';
use Test::More tests => 131;
use vars qw( $class );

BEGIN {
    $class = 'DateTime::Format::HTTP';
    use_ok $class;
}

require Time::Local if $^O eq "MacOS";
my $offset = ($^O eq "MacOS") ? Time::Local::timegm(0,0,0,1,0,70) : 0;

# test str2time for supported dates.  Test cases with 2 digit year
# will probably break in year 2044.
my(@tests) =
(

 'Thu, 03 Feb 1994 00:00:00 GMT',       # proposed new HTTP format
 'Thursday, 03-Feb-94 00:00:00 GMT',    # old rfc850 HTTP format
 'Thursday, 03-Feb-1994 00:00:00 GMT',  # broken rfc850 HTTP format

 'Thu Feb  3 00:00:00 GMT 1994',        # ctime format
 'Thu Feb  3 00:00:00 1994',            # same as ctime, except no TZ

 '03/Feb/1994:00:00:00 0000',   # common logfile format
 '03/Feb/1994:01:00:00 +0100',  # common logfile format
 '02/Feb/1994:23:00:00 -0100',  # common logfile format

 '03 Feb 1994 00:00:00 GMT',    # HTTP format (no weekday)
 '03-Feb-94 00:00:00 GMT',      # old rfc850 (no weekday)
 '03-Feb-1994 00:00:00 GMT',    # broken rfc850 (no weekday)
 '03-Feb-1994 00:00 GMT',       # broken rfc850 (no weekday, no seconds)
 '03-Feb-1994 00:00',           # VMS dir listing format

 '03-Feb-94',    # old rfc850 HTTP format    (no weekday, no time)
 '03-Feb-1994',  # broken rfc850 HTTP format (no weekday, no time)
 '03 Feb 1994',  # proposed new HTTP format  (no weekday, no time)
 '03/Feb/1994',  # common logfile format     (no time, no offset)

 #'Feb  3 00:00',     # Unix 'ls -l' format (can't really test it here)
 'Feb  3 1994',       # Unix 'ls -l' format

 "02-03-94  12:00AM", # Windows 'dir' format

 # ISO 8601 formats
 '1994-02-03 00:00:00 +0000',
 '1994-02-03',
 '19940203',
 '1994-02-03T00:00:00+0000',
 '1994-02-02T23:00:00-0100',
 '1994-02-02T23:00:00-01:00',
 '1994-02-03T00:00:00 Z',
 '19940203T000000Z',
 '199402030000',

 # A few tests with extra space at various places
 '  03/Feb/1994      ',
 '  03   Feb   1994  0:00  ',
);

{
    my $time = (760233600 + $offset);  # assume broken POSIX counting of seconds
    $time = DateTime->from_epoch( epoch => $time );

    for (@tests)
    {
        my $t = $class->parse_datetime($_, /GMT/i ? () : ('GMT'));
        my $t2 = $class->parse_datetime(lc($_) => 'GMT' );
        my $t3 = $class->parse_datetime(uc($_) => 'GMT' );

        #diag "'$_'  =>  $t";
        if ($t->epoch != $time->epoch )
        {
            diag "difference is: ".($t->epoch - $time->epoch);
        }

        is ( $t->epoch, $time->epoch, "str2time (1): $_" );
        is ( $t2->epoch, $time->epoch, "str2time (2): $_" );
        is ( $t3->epoch, $time->epoch, "str2time (3): $_" );
    }

    # test time2str
    die "time2str failed"
        unless $class->format_datetime($time) eq 'Thu, 03 Feb 1994 00:00:00 GMT';
}

{
    # test the 'ls -l' format with missing year$
    # round to nearest minute 3 days ago.
    my $time = int((time - 3 * 24*60*60) /60)*60;
    my ($min, $hr, $mday, $mon) = (gmtime $time)[1,2,3,4];
    $mon = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
    my $str = sprintf("$mon %02d %02d:%02d", $mday, $hr, $min);
    my $t = $class->parse_datetime($str);
    is( $t->epoch, $time ); #, "str2time ls -l: '$str'  =>  $t ($time)\n");
}

for (undef, '', 'Garbage',
     'Mandag 16. September 1996',
     '1980-00-01',
     '1980-13-01',
     '1980-01-00',
     '1980-01-32',
     '1980-01-01 25:00:00',
     '1980-01-01 00:61:00',
    )
{
    my $desc = defined $_ ? "'$_'" : "undef";
    $desc .= ' does not parse';

    my $ok = ! defined eval { $class->parse_datetime($_) };
    ok( $ok, $desc );
}

my $conv = sub {
    my $str = shift;
    $class->format_iso( $class->parse_datetime( $str ) );
};

my $t;

$t = $conv->("11-12-96  0:00AM");
is($t => "1996-11-12 00:00:00", $t);

$t = $conv->("11-12-96 12:00AM");
is($t => "1996-11-12 00:00:00", $t);

$t = $conv->("11-12-96  0:00PM");
is($t => "1996-11-12 12:00:00", $t);

$t = $conv->("11-12-96 12:00PM");
is($t => "1996-11-12 12:00:00", $t);

$t = $conv->("11-12-96  1:05AM");
is($t => "1996-11-12 01:05:00", $t);

$t = $conv->("11-12-96 12:05AM");
is($t => "1996-11-12 00:05:00", $t);

$t = $conv->("11-12-96  1:05PM");
is($t => "1996-11-12 13:05:00", $t);

$t = $conv->("11-12-96 12:05PM");
is($t => "1996-11-12 12:05:00", $t);

my $dt = $class->parse_datetime("2000-01-01 00:00:01.234");
$t = $dt->epoch;
ok(
    abs(($t - int($t)) - 0.234) > 0.000001,
    "FRAC $t = ".$class->format_iso($dt)
);
is($dt->microsecond, 234_000, '.234s == 234_000us');
is($dt->nanosecond, 234_000_000, '.234s == 234_000_000ns');

$dt = $class->parse_datetime("2010-06-26T15:14:33.400753");
$t = $dt->epoch;
ok(
    abs(($t - int($t)) - 0.400753) > 0.000001,
    "FRAC $t = ".$class->format_iso($dt)
);
is($dt->microsecond, 400_753, '.400753s == 400_753us');
is($dt->nanosecond, 400_753_000, '.400753s == 400_753_000ns');

for my $ns (qw(1 12 123 1234 499999999 500000000 500000001 999753123 999999999)) {
    $dt = $class->parse_datetime(sprintf("2010-06-26T15:14:33.%09d", $ns));
    is($dt->nanosecond, $ns, ".${ns}s == ${ns}ns");
}

$a = $class->format_iso( );
$b = $class->format_iso( DateTime->from_epoch( epoch => 500000 ) );

my $az = $class->format_isoz( );
my $bz = $class->format_isoz( DateTime->from_epoch( epoch => 500000 ) );

for ($a,  $b)  {
  like( $_ => qr/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$/, "time2iso($_)" );
}
for ($az, $bz) {
  like( $_ => qr/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\dZ$/, "time2isoz($_)" );
}

{
    # format_isoz must output date in UTC
    my $eastern_date = DateTime->new(
        year   => 2010,
        month  => 10,
        day    => 21,
        hour   => 13,
        minute => 8,
        second => 23,
        time_zone => 'America/New_York',
    );

    # Get the ISO "Z" format of the eastern zone date time
    my $isoz = $class->format_isoz($eastern_date);

    # Get the actual UTC date time
    my $utc = $eastern_date->clone->set_time_zone('UTC');

    is($isoz, $class->format_isoz($utc), 'format_isoz converts to UTC time zone');
    is($eastern_date->time_zone->name, 'America/New_York', 'format_isoz does not modify input date\'s time zone');
}
