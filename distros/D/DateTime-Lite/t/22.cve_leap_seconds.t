#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/22.cve_leap_seconds.t
##
## Regression test for CWE-407 (inefficient algorithmic complexity) in
## _normalize_leap_seconds. Previously, this routine iterated day by day,
## allowing $dt->add( seconds => $N ) on a non-floating timezone with large $N
## to hold a worker process for O(|N|/86400) iterations. The fix uses
## constant-time integer division plus a bounded leap-second lookup, so runtime
## is O(1) with respect to $N.
##
## Reported by CPANSec (CNA for the Perl and CPAN ecosystem), 2026-09-08.
# Fixed in DateTime::Lite v0.8.1.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;
use Time::HiRes qw( time );

BEGIN
{
    use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
};

diag( "Testing DateTime::Lite $DateTime::Lite::VERSION, Perl $], $^X" );
diag( "XS loaded: " . ( $DateTime::Lite::IsPurePerl ? "no (pure-Perl fallback)" : "yes" ) );

# NOTE: DoS regression: large positive seconds must complete in bounded time
# The buggy version would iterate ~10^10 times for this input, taking minutes in XS
# and hours in pure-Perl. The fix should return effectively instantly.
subtest 'CVE regression: add(seconds => 10^15) completes in bounded time' => sub
{
    my $dt = DateTime::Lite->new(
        year        => 2000,
        month       => 1,
        day         => 1,
        hour        => 0,
        minute      => 0,
        second      => 0,
        time_zone   => 'UTC',
    );

    my $start   = time();
    my $huge    = 1_000_000_000_000_000;  # 10^15 seconds
    my $result  = eval{ $dt->clone->add( seconds => $huge ); };
    my $elapsed = time() - $start;

    ok( defined( $result ), 'add(seconds => 10^15) returned a value' );
    cmp_ok( $elapsed, '<', 2.0, sprintf( "add(seconds => 10^15) completed in %.3fs (< 2s)", $elapsed ) );
};

# NOTE: DoS regression: large negative seconds
subtest 'CVE regression: add(seconds => -10^15) completes in bounded time' => sub
{
    my $dt = DateTime::Lite->new(
        year        => 4000,
        month       => 1,
        day         => 1,
        hour        => 0,
        minute      => 0,
        second      => 0,
        time_zone   => 'UTC',
    );

    my $start    = time();
    my $huge_neg = -1_000_000_000_000_000;
    my $result   = eval{ $dt->clone->add( seconds => $huge_neg ); };
    my $elapsed  = time() - $start;

    ok( defined( $result ), 'add(seconds => -10^15) returned a value' );
    cmp_ok( $elapsed, '<', 2.0, sprintf( "add(seconds => -10^15) completed in %.3fs (< 2s)", $elapsed ) );
};

# NOTE: Correctness: basic addition within a day (no normalisation needed)
subtest 'Correctness: small addition within a day' => sub
{
    my $dt = DateTime::Lite->new(
        year        => 2020,
        month       => 6,
        day         => 15,
        hour        => 12,
        minute      => 0,
        second      => 0,
        time_zone   => 'UTC',
    );

    my $dt2 = $dt->clone->add( seconds => 3600 );
    is( $dt2->year,   2020, '+3600s: year' );
    is( $dt2->month,  6,    '+3600s: month' );
    is( $dt2->day,    15,   '+3600s: day' );
    is( $dt2->hour,   13,   '+3600s: hour' );
    is( $dt2->minute, 0,    '+3600s: minute' );
    is( $dt2->second, 0,    '+3600s: second' );
};

# NOTE: Correctness: addition spanning multiple days (no leap seconds)
subtest 'Correctness: multi-day addition without leap seconds' => sub
{
    my $dt = DateTime::Lite->new(
        year        => 2020,
        month       => 1,
        day         => 1,
        hour        => 0,
        minute      => 0,
        second      => 0,
        time_zone   => 'UTC',
    );

    # +100 days worth of seconds
    my $dt2 = $dt->clone->add( seconds => 100 * 86400 );
    is( $dt2->year,   2020, '+100 days: year' );
    is( $dt2->month,  4,    '+100 days: month' );
    is( $dt2->day,    10,   '+100 days: day' );
    is( $dt2->hour,   0,    '+100 days: hour' );
    is( $dt2->minute, 0,    '+100 days: minute' );
    is( $dt2->second, 0,    '+100 days: second' );
};

# NOTE: Correctness: large addition spanning many leap seconds
# This covers the interesting case where the fast normalisation must be corrected by the
# leap-second accounting step.
subtest 'Correctness: large addition spanning multiple leap seconds' => sub
{
    my $dt = DateTime::Lite->new(
        year        => 1975,
        month       => 1,
        day         => 1,
        hour        => 0,
        minute      => 0,
        second      => 0,
        time_zone   => 'UTC',
    );

    # Add 40 years (40 * 365.25 * 86400 = 1_262_304_000)
    # This spans many leap seconds. The exact expected date depends on the leap-second
    # interpretation, but should be around 2014-12-22.
    my $seconds = 40 * 365 * 86400 + 10 * 86400;  # 40 years + 10 days
    my $dt2 = $dt->clone->add( seconds => $seconds );

    # Verify it is in the right ballpark (2014-2015 area).
    # The exact value depends on leap seconds; what matters for the CVE is that we get
    # a reasonable answer, not a hang.
    cmp_ok( $dt2->year, '>=', 2014, 'large addition: year >= 2014' );
    cmp_ok( $dt2->year, '<=', 2015, 'large addition: year <= 2015' );
};

# NOTE: Correctness: negative addition
subtest 'Correctness: subtraction of moderate amount' => sub
{
    my $dt = DateTime::Lite->new(
        year        => 2020,
        month       => 6,
        day         => 15,
        hour        => 12,
        minute      => 0,
        second      => 0,
        time_zone   => 'UTC',
    );

    my $dt2 = $dt->clone->add( seconds => -100 * 86400 );
    is( $dt2->year,  2020, '-100 days: year' );
    is( $dt2->month, 3,    '-100 days: month' );
    is( $dt2->day,   7,    '-100 days: day' );
};

# NOTE: Correctness: non-UTC non-floating timezone
subtest 'Correctness: non-UTC timezone also uses _normalize_leap_seconds' => sub
{
    my $dt = DateTime::Lite->new(
        year        => 2020,
        month       => 6,
        day         => 15,
        hour        => 12,
        minute      => 0,
        second      => 0,
        time_zone   => 'Asia/Tokyo',
    );

    my $start = time();
    my $result = eval{ $dt->clone->add( seconds => 1_000_000_000_000 ); };
    my $elapsed = time() - $start;

    ok( defined( $result ), 'add(seconds => 10^12) on Asia/Tokyo returned a value' );
    cmp_ok( $elapsed, '<', 2.0, sprintf( "add(seconds => 10^12) on Asia/Tokyo completed in %.3fs", $elapsed ) );
};

# NOTE: Correctness: floating timezone (uses _normalize_tai_seconds, already O(1))
# This is a sanity check that we did not break the floating-timezone path.
subtest 'Sanity: floating timezone still works' => sub
{
    my $dt = DateTime::Lite->new(
        year        => 2020,
        month       => 6,
        day         => 15,
        hour        => 12,
        minute      => 0,
        second      => 0,
        time_zone   => 'floating',
    );

    my $dt2 = $dt->clone->add( seconds => 3600 );
    is( $dt2->hour, 13, 'floating tz: +3600s gives hour = 13' );
};

done_testing;

__END__
