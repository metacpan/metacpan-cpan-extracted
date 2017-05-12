#!perl
use strict;
use Test::More tests => 29;

BEGIN
{
    use_ok("DateTime::Event::Lunar");
}

use constant MAX_DELTA_MINUTES => 30;

# http://aa.usno.navy.mil/data/docs/MoonPhase.html
my @dates = (
    [ 2000,  2,  5, 13,  3 ],
    [ 2001,  8, 19,  2, 55 ],
    [ 2002,  6, 10, 23, 46 ],
    [ 2003, 12, 23,  9, 43 ],
    [ 2004,  9, 14, 14, 29 ],
    [ 2005,  8,  5,  3,  5 ],
    [ 2006,  5, 27,  5, 26 ],
);

foreach my $d_data (@dates) {
    my %args;

    @args{ qw(year month day hour minute time_zone) } = ( @$d_data, 'UTC' );
    my $dt = DateTime->new(%args);

    # if $dt is a new moon, 7 days prior to this date is *definitely*
    # after the last new moon, but before the one expressed by $dt
    my $dt0 = $dt - DateTime::Duration->new(days => 7);

    my $new_moon = DateTime::Event::Lunar->new_moon();
    my $next_new_moon = $new_moon->next($dt0);

    check_deltas($dt, $next_new_moon);

    # Same as before, but now we try $dt + 7 days
    my $dt1 = $dt + DateTime::Duration->new(days => 7);
    my $prev_new_moon = $new_moon->previous($dt1);

    check_deltas($dt, $prev_new_moon);
}

sub check_deltas
{
    my($expected, $actual) = @_;

    my $diff = $expected - $actual;
    ok($diff);

    # make sure the deltas do not exceed 3 hours
    my %deltas = $diff->deltas;
    ok( $deltas{months} == 0 &&
        $deltas{days} == 0 &&
        abs($deltas{minutes}) < MAX_DELTA_MINUTES,
        "Expected $expected, got $actual") or
    diag( "Expected new moon date was " . 
        $expected->strftime("%Y/%m/%d %T") . " but instead we got " .
        $actual->strftime("%Y/%m/%d %T") .
        " which is more than allowed delta of " .
        MAX_DELTA_MINUTES . " minutes" );
}
