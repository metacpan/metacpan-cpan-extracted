#!/usr/bin/env perl
#
# Compare the throughput of the Algorithm::EventsPerSecond backends.
#
# The backend is picked once when the module loads, so each code path
# runs in its own child perl: one default (XS if available) and one
# with ALGORITHM_EVENTSPERSECOND_PP=1 (pure Perl). Run this after
# building for XS numbers:
#
#   perl Makefile.PL && make && ./benchmark.pl
#   ./benchmark.pl --time 5 --windows 60,3600
#
# Which SIMD flavor the XS column uses depends on how the .so was
# compiled; rebuild with IF_ARCH=native to benchmark AVX2/SSE4.2.

use 5.006;
use strict;
use warnings;
use FindBin ();
use Getopt::Long qw(GetOptions);

my @incs;

BEGIN {
    @incs = grep { -d }
        ( "$FindBin::Bin/blib/arch", "$FindBin::Bin/blib/lib", "$FindBin::Bin/lib" );
    unshift @INC, @incs;
}

my $time    = 2;
my $windows = '60,600,3600';
GetOptions(
    'time=f'    => \$time,
    'windows=s' => \$windows,
    'help'      => sub { print "usage: $0 [--time seconds] [--windows csv]\n"; exit 0 },
) or die "usage: $0 [--time seconds] [--windows csv]\n";

my @windows = grep { /^\d+$/ && $_ > 0 } split /,/, $windows;
die "no valid window sizes in --windows\n" unless @windows;

#
# child mode: benchmark whatever backend loads and emit tab-separated
# "label \t ops-per-second" lines for the parent to collate
#
if ( $ENV{AEPS_BENCH_CHILD} ) {
    require Algorithm::EventsPerSecond;
    require Benchmark;

    my $backend = Algorithm::EventsPerSecond->backend;
    my $simd    = Algorithm::EventsPerSecond->simd;
    print "BACKEND\t", ( defined $simd ? "$backend ($simd)" : $backend ), "\n";

    my $bench = sub {
        my ( $label, $per_iter, $code ) = @_;
        my $t = Benchmark::countit( $time, $code );
        my $cpu = $t->cpu_a || 1e-9;
        printf "%s\t%.1f\n", $label, $t->iters * $per_iter / $cpu;
    };

    {
        my $m = Algorithm::EventsPerSecond->new( window => $windows[0] );
        $bench->( 'mark, 1 event/call',    1,   sub { $m->mark } );
        $bench->( 'mark, 100 events/call', 100, sub { $m->mark(100) } );
    }

    for my $w (@windows) {
        my $m = Algorithm::EventsPerSecond->new( window => $w );
        $m->mark;
        $bench->( "count, window=$w", 1, sub { my $x = $m->count } );
        $bench->( "rate, window=$w",  1, sub { my $x = $m->rate } );

        # a realistic consumer: record events, check the rate every 100
        my $i = 0;
        $bench->(
            "mark + rate/100, window=$w",
            1, sub { $m->mark; $m->rate if ++$i % 100 == 0; }
        );
    }

    exit 0;
}

#
# parent mode: run one child per backend and print a comparison
#
sub run_child {
    my %env = ( @_, AEPS_BENCH_CHILD => 1 );
    local @ENV{ keys %env } = values %env;

    my @cmd = (
        $^X, ( map { "-I$_" } @incs ),
        $0, '--time', $time, '--windows', join( ',', @windows ),
    );
    open my $fh, '-|', @cmd or die "cannot run child benchmark: $!\n";

    my ( $backend, %rate, @order );
    while ( my $line = <$fh> ) {
        chomp $line;
        my ( $label, $value ) = split /\t/, $line, 2;
        next unless defined $value;
        if ( $label eq 'BACKEND' ) { $backend = $value; next; }
        $rate{$label} = $value;
        push @order, $label;
    }
    close $fh or die "child benchmark exited non-zero\n";
    die "child produced no results\n" unless defined $backend;

    return { backend => $backend, rate => \%rate, order => \@order };
}

sub commify {
    my $n = sprintf '%.0f', shift;
    1 while $n =~ s/^(\d+)(\d{3})/$1,$2/;
    return $n;
}

print "Algorithm::EventsPerSecond benchmark (perl $], ${time}s per measurement)\n";

my $pp = run_child( ALGORITHM_EVENTSPERSECOND_PP => 1 );
my $xs = run_child();

if ( $xs->{backend} eq $pp->{backend} ) {
    print "XS backend not available (build it with: perl Makefile.PL && make);\n";
    print "showing pure Perl only. All figures are calls/second.\n\n";
    printf "  %-32s %15s\n", '', $pp->{backend};
    printf "  %-32s %15s\n", $_, commify( $pp->{rate}{$_} )
        for @{ $pp->{order} };
    exit 0;
}

print "All figures are events or calls per second, higher is better.\n\n";
printf "  %-32s %15s %15s %9s\n", '', $pp->{backend}, $xs->{backend}, 'speedup';
for my $label ( @{ $pp->{order} } ) {
    my $p = $pp->{rate}{$label};
    my $x = $xs->{rate}{$label};
    next unless defined $x;
    printf "  %-32s %15s %15s %8.1fx\n",
        $label, commify($p), commify($x), $p ? $x / $p : 0;
}
