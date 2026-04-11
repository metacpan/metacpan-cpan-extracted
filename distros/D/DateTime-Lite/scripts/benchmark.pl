#!/usr/bin/env perl
##----------------------------------------------------------------------------
## DateTime::Lite - scripts/benchmark.pl
##
## Compares DateTime and DateTime::Lite on four axes:
##   - Module count loaded into %INC
##   - Declared runtime prerequisites
##   - CPU / wall-clock time for common operations
##   - Resident memory (RSS) after loading
##
## Architecture: the parent process forks before loading any module.
## Each child loads only its own module set, measures what it needs,
## serialises results to a temp file, and exits.  The parent aggregates
## and prints.  This guarantees a clean %INC for every measurement,
## avoiding false results caused by shared module state.
##
## Usage:
##   perl -Iblib/lib -Iblib/arch scripts/benchmark.pl [--iterations N]
##   perl -Iblib/lib -Iblib/arch scripts/benchmark.pl --csv
##
## DateTime must be installed on the system.
## DateTime::Lite is loaded from blib/ (run `make` first).
##----------------------------------------------------------------------------
use v5.10.1;
use strict;
use warnings;

# These modules are loaded BEFORE any fork so they are available in every
# child via copy-on-write.  They must not pull in DateTime or DateTime::Lite.
use POSIX         qw( WIFEXITED WEXITSTATUS );
use File::Temp    qw( tempfile );
use Getopt::Long  qw( GetOptions );
use Scalar::Util  qw( looks_like_number );

my $ITERATIONS = 10_000;
my $CSV        = 0;
GetOptions(
    'iterations=i' => \$ITERATIONS,
    'csv'          => \$CSV,
) or die "Usage: $0 [--iterations N] [--csv]\n";

# Snapshot @INC before any fork so children inherit it correctly.
my @INC_SNAP = @INC;

# ---------------------------------------------------------------------------
# IPC helpers
# ---------------------------------------------------------------------------

# Run a closure in a child process.
# The closure receives a CODE ref it must call with a hashref of results.
# The parent waits and returns that hashref.
sub in_fork
{
    my $code = shift;

    my( $fh, $fname ) = tempfile( UNLINK => 1 );
    close $fh;

    my $pid = fork();
    die "fork() failed: $!" unless defined $pid;

    if( $pid == 0 )
    {
        # Child: restore @INC so blib paths are available
        @INC = @INC_SNAP;

        # Run measurement, get results hashref
        my $results = {};
        eval { $code->( $results ) };
        if( $@ )
        {
            warn "Child error: $@";
            exit 1;
        }

        # Serialise to temp file and exit cleanly
        require JSON;
        open my $out, '>', $fname or die "Cannot write $fname: $!";
        print $out JSON->new->encode( $results );
        close $out;
        exit 0;
    }

    # Parent: wait for child
    waitpid( $pid, 0 );
    my $status = $?;
    die "Child exited with error status $status\n"
        unless WIFEXITED($status) && WEXITSTATUS($status) == 0;

    require JSON;
    open my $in, '<', $fname or die "Cannot read $fname: $!";
    return JSON->new->decode( do { local $/; <$in> } );
}

# ---------------------------------------------------------------------------
# Measurement helpers (run inside children)
# ---------------------------------------------------------------------------

sub _rss_kb
{
    open my $f, '<', '/proc/self/status' or return undef;
    while( <$f> ) { /^VmRSS:\s+(\d+)/ and return $1 }
    return undef;
}

sub _bench
{
    my( $n, $code ) = @_;
    require Time::HiRes;
    require POSIX;
    $code->() for 1 .. 3;    # warm-up
    my $cpu0 = Time::HiRes::clock_gettime( Time::HiRes::CLOCK_PROCESS_CPUTIME_ID() );
    my $w0   = Time::HiRes::time();
    $code->() for 1 .. $n;
    return(
        Time::HiRes::time() - $w0,
        Time::HiRes::clock_gettime( Time::HiRes::CLOCK_PROCESS_CPUTIME_ID() ) - $cpu0,
    );
}

sub _prereqs
{
    my $path = shift;
    return 'n/a' unless -r $path;
    require JSON;
    open my $fh, '<', $path or return 'n/a';
    my $meta    = JSON->new->decode( do { local $/; <$fh> } );
    my $runtime = $meta->{prereqs}{runtime}{requires} // {};
    return scalar( grep { $_ ne 'perl' } keys %$runtime );
}

# ---------------------------------------------------------------------------
# Fork 1: DateTime family
# ---------------------------------------------------------------------------

my $dt = in_fork( sub
{
    my $r = shift;
    require DateTime;
    require DateTime::TimeZone;
    $r->{mods_full}   = scalar keys %INC;
    $r->{rss_full}    = _rss_kb() // 0;
    $r->{version}     = "$DateTime::VERSION";

    # Trigger lazy zone loading to get real-world RSS.
    # DateTime::TimeZone loads each zone's .pm on first use (+39 modules
    # and ~10 MB on the first call alone).
    DateTime->new( year=>2026, month=>4, day=>9,
                   time_zone=>'America/New_York' );
    $r->{mods_after_tz} = scalar keys %INC;
    $r->{rss_after_tz}  = _rss_kb() // 0;

    my $N = $ITERATIONS;
    my( $w, $c );

    ( $w, $c ) = _bench( $N, sub {
        DateTime->new( year=>2026, month=>4, day=>9, hour=>12,
                       time_zone=>'UTC' );
    });
    $r->{new_utc_wall} = $w; $r->{new_utc_cpu} = $c;

    ( $w, $c ) = _bench( $N, sub {
        DateTime->new( year=>2026, month=>4, day=>9, hour=>12,
                       time_zone=>'America/New_York' );
    });
    $r->{new_ny_wall} = $w;

    ( $w, $c ) = _bench( $N, sub {
        DateTime->now( time_zone=>'UTC' );
    });
    $r->{now_wall} = $w;

    my $dt1 = DateTime->new( year=>2026, month=>4, day=>9,
                             hour=>12, time_zone=>'UTC' );
    ( $w, $c ) = _bench( $N, sub {
        $dt1->year; $dt1->month; $dt1->day; $dt1->epoch;
    });
    $r->{acc_wall} = $w;

    ( $w, $c ) = _bench( $N, sub {
        $dt1->clone->add( days=>30, hours=>6 );
    });
    $r->{add_wall} = $w;

    ( $w, $c ) = _bench( $N, sub {
        $dt1->strftime('%Y-%m-%dT%H:%M:%S');
    });
    $r->{strf_wall} = $w;

    # TimeZone warm cache
    DateTime::TimeZone->new( name=>'America/New_York' );
    ( $w, $c ) = _bench( $N, sub {
        DateTime::TimeZone->new( name=>'America/New_York' );
    });
    $r->{tz_warm_wall} = $w;
});

# ---------------------------------------------------------------------------
# Fork 2: DateTime::TimeZone alone (clean %INC for accurate module count)
# ---------------------------------------------------------------------------

my $dt_tz = in_fork( sub
{
    my $r = shift;
    require DateTime::TimeZone;
    $r->{mods_tz}  = scalar keys %INC;
    $r->{rss_tz}   = _rss_kb() // 0;
});

# ---------------------------------------------------------------------------
# Fork 3: DateTime::Lite family
# ---------------------------------------------------------------------------

my $dtl = in_fork( sub
{
    my $r = shift;
    require DateTime::Lite;
    require DateTime::Lite::TimeZone;
    $r->{mods_full}   = scalar keys %INC;
    $r->{rss_full}    = _rss_kb() // 0;
    $r->{version}     = "$DateTime::Lite::VERSION";

    # Same measurement as for DateTime: after using a named zone.
    # DTL::TimeZone uses SQLite so module count and RSS stay flat.
    DateTime::Lite->new( year=>2026, month=>4, day=>9,
                         time_zone=>'America/New_York' );
    $r->{mods_after_tz} = scalar keys %INC;
    $r->{rss_after_tz}  = _rss_kb() // 0;

    my $N = $ITERATIONS;
    my( $w, $c );

    ( $w, $c ) = _bench( $N, sub {
        DateTime::Lite->new( year=>2026, month=>4, day=>9, hour=>12,
                             time_zone=>'UTC' );
    });
    $r->{new_utc_wall} = $w;

    ( $w, $c ) = _bench( $N, sub {
        DateTime::Lite->new( year=>2026, month=>4, day=>9, hour=>12,
                             time_zone=>'America/New_York' );
    });
    $r->{new_ny_wall} = $w;

    ( $w, $c ) = _bench( $N, sub {
        DateTime::Lite->now( time_zone=>'UTC' );
    });
    $r->{now_wall} = $w;

    my $dtl1 = DateTime::Lite->new( year=>2026, month=>4, day=>9,
                                    hour=>12, time_zone=>'UTC' );
    ( $w, $c ) = _bench( $N, sub {
        $dtl1->year; $dtl1->month; $dtl1->day; $dtl1->epoch;
    });
    $r->{acc_wall} = $w;

    ( $w, $c ) = _bench( $N, sub {
        $dtl1->clone->add( days=>30, hours=>6 );
    });
    $r->{add_wall} = $w;

    ( $w, $c ) = _bench( $N, sub {
        $dtl1->strftime('%Y-%m-%dT%H:%M:%S');
    });
    $r->{strf_wall} = $w;

    # TimeZone: no mem cache
    DateTime::Lite::TimeZone->new( name=>'America/New_York' );
    ( $w, $c ) = _bench( $N, sub {
        DateTime::Lite::TimeZone->new( name=>'America/New_York' );
    });
    $r->{tz_warm_wall} = $w;

    # new() with named zone string AND mem cache
    DateTime::Lite::TimeZone->enable_mem_cache;
    DateTime::Lite->new( year=>2026, month=>4, day=>9, hour=>12,
                         time_zone=>'America/New_York' ); # prime cache
    ( $w, $c ) = _bench( $N, sub {
        DateTime::Lite->new( year=>2026, month=>4, day=>9, hour=>12,
                             time_zone=>'America/New_York' );
    });
    $r->{new_ny_cache_wall} = $w;
    DateTime::Lite::TimeZone->disable_mem_cache;

    # TimeZone: with mem cache
    DateTime::Lite::TimeZone->enable_mem_cache;
    DateTime::Lite::TimeZone->new( name=>'America/New_York' );
    ( $w, $c ) = _bench( $N, sub {
        DateTime::Lite::TimeZone->new( name=>'America/New_York' );
    });
    $r->{tz_cache_wall} = $w;
    DateTime::Lite::TimeZone->disable_mem_cache;
});

# ---------------------------------------------------------------------------
# Fork 4: DateTime::Lite::TimeZone alone
# ---------------------------------------------------------------------------

my $dtl_tz = in_fork( sub
{
    my $r = shift;
    require DateTime::Lite::TimeZone;
    $r->{mods_tz}  = scalar keys %INC;
    $r->{rss_tz}   = _rss_kb() // 0;
});

# ---------------------------------------------------------------------------
# Fork 5 & 6: load times (cold require, clean process)
# ---------------------------------------------------------------------------

my $dt_load = in_fork( sub
{
    my $r = shift;
    require Time::HiRes;
    my $t0 = Time::HiRes::time();
    require DateTime;
    $r->{load_time} = Time::HiRes::time() - $t0;
});

my $dtl_load = in_fork( sub
{
    my $r = shift;
    require Time::HiRes;
    my $t0 = Time::HiRes::time();
    require DateTime::Lite;
    $r->{load_time} = Time::HiRes::time() - $t0;
});

# ---------------------------------------------------------------------------
# Prerequisites from META.json
# ---------------------------------------------------------------------------

my $script_dir = $0;  $script_dir =~ s{/[^/]+$}{};
my $dtl_prereqs = _prereqs( "$script_dir/../META.json" );

# DateTime META.json location
my $dt_meta = do {
    ( my $dir = $INC{'DateTime.pm'} // '' ) =~ s{/DateTime\.pm$}{};
    "$dir/../META.json";
};
my $dt_prereqs = _prereqs( $dt_meta );

# ---------------------------------------------------------------------------
# Print helpers
# ---------------------------------------------------------------------------

my @csv_rows;

sub fmt { sprintf '%.1f', $_[0] }

sub row
{
    my( $label, $dt_val, $dtl_val, $unit ) = @_;
    $unit //= '';
    if( $CSV )
    {
        push @csv_rows, [ $label, $dt_val, $dtl_val, $unit ];
    }
    else
    {
        printf "  %-46s  %9s  %9s  %s\n",
            $label, $dt_val, $dtl_val, $unit;
    }
}

sub section { print "\n--- $_[0] ---\n" unless $CSV }
sub header
{
    return if $CSV;
    printf "  %-46s  %9s  %9s  %s\n",
        'Operation', 'DateTime', 'DTL', 'unit';
    printf "  %s\n", '-' x 78;
}

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

unless( $CSV )
{
    print "=" x 80, "\n";
    print "DateTime vs DateTime::Lite  -  benchmark\n";
    printf "  DateTime version:       %s\n", $dt->{version}  // '?';
    printf "  DateTime::Lite version: %s\n", $dtl->{version} // '?';
    printf "  Perl:                   %s (%s)\n", $], $^O;
    printf "  Iterations:             %d\n", $ITERATIONS;
    printf "  Platform:               %s\n", (POSIX::uname())[4] // '?';
    print "=" x 80, "\n";
}

my $N = $ITERATIONS;

section( 'Module count  (entries in %INC after loading, measured in clean fork)' );
header();
row( 'use Module',         $dt->{mods_full},    $dtl->{mods_full},   'modules' );
row( 'use TimeZone alone', $dt_tz->{mods_tz},   $dtl_tz->{mods_tz},  'modules' );
row( 'Runtime prereqs (META.json)',
     $dt_prereqs,          $dtl_prereqs,         'packages' );

section( 'Load time  (cold require, measured in clean fork)' );
header();
row( 'require Module',
     sprintf( '%.3f', $dt_load->{load_time} ),
     sprintf( '%.3f', $dtl_load->{load_time} ), 'seconds' );

section( 'Memory  (RSS kB, measured in clean fork after loading)' );
header();
row( 'RSS: use Module (before any zone use)',
     $dt->{rss_full},   $dtl->{rss_full},   'kB' );
row( 'RSS: after first named zone construction',
     $dt->{rss_after_tz},  $dtl->{rss_after_tz},  'kB' );
row( 'RSS: use TimeZone alone',
     $dt_tz->{rss_tz},  $dtl_tz->{rss_tz},  'kB' );
row( 'Modules after first named zone construction',
     $dt->{mods_after_tz}, $dtl->{mods_after_tz}, 'modules' );
print "  Note: DT::TimeZone loads one .pm per zone on first use;\n"
    . "        DTL::TimeZone uses SQLite so module count stays flat.\n"
    . "        DTL RSS includes DBD::SQLite (~14 MB compiled native code).\n"
    unless $CSV;

section( "CPU / wall-clock  ($ITERATIONS iterations, µs per call, measured in clean fork)" );
header();

row( 'new( UTC )',
     fmt( $dt->{new_utc_wall} / $N * 1e6 ),
     fmt( $dtl->{new_utc_wall}/ $N * 1e6 ), 'µs/call' );
row( 'new( named zone, string )',
     fmt( $dt->{new_ny_wall}  / $N * 1e6 ),
     fmt( $dtl->{new_ny_wall} / $N * 1e6 ), 'µs/call' );
row( 'new( named zone, mem cache enabled )',
     fmt( $dt->{new_ny_wall}                     / $N * 1e6 ),
     fmt( ( $dtl->{new_ny_cache_wall} // 0 )     / $N * 1e6 ), 'µs/call' );
row( 'now( UTC )',
     fmt( $dt->{now_wall}  / $N * 1e6 ),
     fmt( $dtl->{now_wall} / $N * 1e6 ), 'µs/call' );
row( 'year + month + day + epoch',
     sprintf( '%.3f', $dt->{acc_wall}  / $N * 1e6 ),
     sprintf( '%.3f', $dtl->{acc_wall} / $N * 1e6 ), 'µs/call' );
row( 'clone + add( days + hours )',
     fmt( $dt->{add_wall}  / $N * 1e6 ),
     fmt( $dtl->{add_wall} / $N * 1e6 ), 'µs/call' );
row( 'strftime',
     fmt( $dt->{strf_wall}  / $N * 1e6 ),
     fmt( $dtl->{strf_wall} / $N * 1e6 ), 'µs/call' );
row( 'TimeZone->new (warm, no mem cache)',
     fmt( $dt->{tz_warm_wall}   / $N * 1e6 ),
     fmt( $dtl->{tz_warm_wall}  / $N * 1e6 ), 'µs/call' );
row( 'TimeZone->new (DTL mem cache enabled)',
     fmt( $dt->{tz_warm_wall}    / $N * 1e6 ),
     fmt( $dtl->{tz_cache_wall}  / $N * 1e6 ), 'µs/call' );

if( $CSV )
{
    print "operation,DateTime,DateTime::Lite,unit\n";
    printf "%s,%s,%s,%s\n", @$_ for @csv_rows;
}
else
{
    print "\n", "=" x 80, "\n";
}

__END__

=head1 NAME

benchmark.pl - Compare DateTime and DateTime::Lite performance

=head1 SYNOPSIS

    cd DateTime-Lite-vX.X.X
    perl Makefile.PL && make
    perl -Iblib/lib -Iblib/arch scripts/benchmark.pl

    perl scripts/benchmark.pl --iterations 20000
    perl scripts/benchmark.pl --csv > results.csv

=head1 DESCRIPTION

Forks the process before loading any module so that every measurement
runs in a clean C<%INC>.  Results are serialised to temp files and
aggregated by the parent.

=head1 OPTIONS

=over 4

=item C<--iterations N>

Timing loop iterations (default: 10_000).

=item C<--csv>

Machine-readable CSV output.

=back

=cut
