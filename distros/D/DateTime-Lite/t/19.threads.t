#!perl
##----------------------------------------------------------------------------
## DateTime::Lite::TimeZone - t/19.threads.t
## Thread safety tests for the $DBH and $STHS package-level caches.
## Skipped entirely when Perl is not compiled with useithreads.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;
use Config;
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

unless( $Config{useithreads} )
{
    plan( skip_all => "Perl $^V is not compiled with useithreads, skipping thread safety tests" );
}

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
use_ok( 'DateTime::Lite::TimeZone' ) or BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );

require threads;

my $NUM_THREADS = 10;

# NOTE: Thread safety: TimeZone->new concurrent construction
subtest 'TimeZone->new concurrent construction' => sub
{
    # Each thread constructs a TimeZone object independently.
    # Without the tid-keyed $DBH cache, DBD::SQLite raises:
    # "handle %s is owned by thread %s not current thread"
    my @zones = qw(
        Asia/Tokyo
        America/New_York
        Europe/Paris
        Australia/Sydney
        America/Los_Angeles
        Europe/London
        Asia/Shanghai
        America/Chicago
        Pacific/Auckland
        Asia/Kolkata
    );

    my @threads = map
    {
        my $zone = $zones[ $_ % scalar( @zones ) ];
        threads->create(sub
        {
            my $tz = DateTime::Lite::TimeZone->new( name => $zone );
            return(0) unless( defined( $tz ) );
            return(0) unless( $tz->name eq $zone );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, 'All $NUM_THREADS threads constructed TimeZone objects without error' );
};

# NOTE: Thread safety: resolve_abbreviation concurrent calls
subtest 'resolve_abbreviation concurrent calls' => sub
{
    my @abbrs = qw( JST CET EST PST GMT UTC );

    my @threads = map
    {
        my $abbr = $abbrs[ $_ % scalar( @abbrs ) ];
        threads->create(sub
        {
            my $candidates = DateTime::Lite::TimeZone->resolve_abbreviation(
                $abbr,
                extended => 1,
            );
            return(0) unless( defined( $candidates ) && ref( $candidates ) eq 'ARRAY' );
            return(0) unless( scalar( @$candidates ) > 0 );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, 'All $NUM_THREADS threads called resolve_abbreviation without error' );
};

# NOTE: Thread safety: new() with extended => 1
subtest 'TimeZone->new with extended => 1 concurrent' => sub
{
    my @abbrs = qw( JST CET WET EET HKT );

    my @threads = map
    {
        my $abbr = $abbrs[ $_ % scalar( @abbrs ) ];
        threads->create(sub
        {
            my $tz = DateTime::Lite::TimeZone->new( name => $abbr, extended => 1 );
            diag( "DateTime::Lite::TimeZone returned '", ( $tz // 'undef' ), "' for '$abbr'." ) if( $DEBUG );
            return(0) unless( defined( $tz ) );
            # Result must be a proper IANA canonical name, not the abbreviation
            diag( "DateTime::Lite::TimeZone returned an object that is the same as the abbreviation '$abbr', so it is not good." ) if( $tz->name eq $abbr && $DEBUG );
            return(0) if( $tz->name eq $abbr );
            diag( "Ok, DateTime::Lite::TimeZone returned a proper object for '$abbr'." ) if( $DEBUG );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, 'All $NUM_THREADS threads used extended => 1 without error' );
};

# NOTE: Thread safety: DateTime::Lite->new concurrent with named zone
subtest 'DateTime::Lite->new concurrent with named zone' => sub
{
    my @zones = qw( Asia/Tokyo America/New_York Europe/Paris UTC floating );

    my @threads = map
    {
        my $zone = $zones[ $_ % scalar( @zones ) ];
        threads->create(sub
        {
            my $dt = DateTime::Lite->new(
                year      => 2026,
                month     => 4,
                day       => 23,
                hour      => 12,
                minute    => 0,
                second    => 0,
                time_zone => $zone,
            );
            return(0) unless( defined( $dt ) );
            return(0) unless( $dt->year == 2026 );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, 'All $NUM_THREADS threads constructed DateTime::Lite objects without error' );
};

# NOTE: Thread safety: DateTime::Lite->new with time_zone as hashref
subtest 'DateTime::Lite->new with time_zone hashref concurrent' => sub
{
    my @specs = (
        { name => 'JST',       extended => 1 },
        { name => 'Asia/Tokyo'               },
        { name => 'CET',       extended => 1 },
        { name => 'UTC'                      },
        { name => 'EST',       extended => 1 },
    );

    my @threads = map
    {
        my $spec = $specs[ $_ % scalar( @specs ) ];
        threads->create(sub
        {
            my $dt = DateTime::Lite->new(
                year      => 2026,
                month     => 4,
                day       => 23,
                time_zone => $spec,
            );
            return(0) unless( defined( $dt ) );
            return(0) unless( $dt->year == 2026 );
            return(1);
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, 'All $NUM_THREADS threads used time_zone hashref without error' );
};

# NOTE: Thread safety: shared object, parallel offset lookups
subtest 'Shared TimeZone object parallel offset lookups' => sub
{
    # Construct one object in the main thread, then read from it in
    # multiple threads concurrently. The TimeZone object itself is
    # read-only after construction so this should be safe.
    my $tz = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    ok( defined( $tz ), 'Shared TimeZone object constructed' );

    my @threads = map
    {
        threads->create(sub
        {
            # offset_for_datetime requires a DB lookup (span table)
            my $dt = DateTime::Lite->new(
                year      => 2026,
                month     => 1,
                day       => 15,
                time_zone => 'UTC',
            );
            my $offset = $tz->offset_for_datetime( $dt );
            return(0) unless( defined( $offset ) );
            # New York in January is UTC-5 (EST = -18000 seconds)
            return( $offset == -18000 ? 1 : 0 );
        });
    } 0 .. ( $NUM_THREADS - 1 );

    my $success = 1;
    foreach my $thr ( @threads )
    {
        $success &&= $thr->join();
    }
    ok( $success, 'All $NUM_THREADS threads read offset from shared TimeZone object' );
};

# NOTE: Thread safety: new() with ambiguous abbreviation returns proper error
subtest 'TimeZone->new with ambiguous abbreviation' => sub
{
    local $SIG{__WARN__} = sub{};
    # MSK is genuinely ambiguous: it mapped to both +03:00 and +04:00 at
    # different points in history. new( extended => 1 ) should return an
    # error with a clear message, not the generic 'Unknown time zone'.
    my $tz = DateTime::Lite::TimeZone->new( name => 'MSK', extended => 1 );
    ok( !defined( $tz ), 'MSK with extended => 1 returns undef (ambiguous)' );
    diag( "DateTime::Lite::TimeZone returned the error -> ", DateTime::Lite::TimeZone->error ) if( $DEBUG );
    like(
        DateTime::Lite::TimeZone->error,
        qr/ambiguous/i,
        'Error message mentions ambiguous',
    );
};

done_testing();

__END__
