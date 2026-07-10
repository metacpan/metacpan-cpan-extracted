#!/usr/bin/perl
# benchmarking/bench-axis-fit-accel.pl
#
# Benchmarks axis-mode (classic IF) fit() under each acceleration backend:
#   pure_perl   -- use_c => 0                   (no _rebuild_c_trees)
#   c_serial    -- use_c => 1, use_openmp => 0  (includes _rebuild_c_trees)
#   c_openmp    -- use_c => 1, use_openmp => 1  (same + OpenMP flag set)
#
# Tree building itself is always pure Perl; the difference comes from the
# _rebuild_c_trees() packing step at the end of fit().  OpenMP only affects
# scoring, so c_serial and c_openmp should be nearly identical here --
# seeing that confirmed is the point.
#
# Sections:
#   1. n_trees          -- packing cost grows with tree count
#   2. dataset size     -- subsampling dominates; packing is fixed
#   3. feature count    -- wide sweep (2, 5, 10, 20, 50)
#   4. feature count    -- fine-grained 2-10
#
# Run with:
#   perl -Ilib benchmarking/bench-axis-fit-accel.pl

use strict;
use warnings;
use lib '../lib';
use FindBin;
use lib "$FindBin::Bin";
use BenchAccel qw(wall_cmpthese);
use Algorithm::Classifier::IsolationForest;

use constant PI => 3.14159265358979;

sub gaussian {
	my ( $mu, $sigma ) = @_;
	return $mu + $sigma * sqrt( -2 * log( rand() || 1e-12 ) ) * cos( 2 * PI * rand() );
}

sub make_data {
	my ( $n, $nf ) = @_;
	my @rows = map {
		[ map { gaussian( 0, 1 ) } 1 .. $nf ]
	} 1 .. $n;
	for ( 1 .. int( $n * 0.05 ) ) {
		my $r = 5 + rand() * 3;
		push @rows, [ map { $r * ( rand() > 0.5 ? 1 : -1 ) } 1 .. $nf ];
	}
	return \@rows;
} ## end sub make_data

my $HAS_C      = $Algorithm::Classifier::IsolationForest::HAS_C;
my $HAS_OPENMP = $Algorithm::Classifier::IsolationForest::HAS_OPENMP;

print "=" x 70, "\n";
print " axis-mode fit() accel benchmarks\n";
print " Algorithm::Classifier::IsolationForest\n";
print "=" x 70, "\n";
printf "Backend availability: HAS_C=%d  HAS_OPENMP=%d  HAS_SIMD=%d\n",
	$HAS_C, $HAS_OPENMP,
	$Algorithm::Classifier::IsolationForest::HAS_SIMD;
print "(rates shown as fits/second wall-clock; higher is faster)\n";

# Build the set of accel configs to compare.  Always include pure_perl;
# only include C variants when the backend actually compiled.
sub accel_variants {
	my (%base) = @_;
	my %v = (
		'pure_perl' => sub {
			Algorithm::Classifier::IsolationForest->new( %base, use_c => 0 )->fit( $base{_data} );
		},
	);
	if ($HAS_C) {
		$v{'c_serial'} = sub {
			Algorithm::Classifier::IsolationForest->new(
				%base,
				use_c      => 1,
				use_openmp => 0
			)->fit( $base{_data} );
		};
	}
	if ( $HAS_C && $HAS_OPENMP ) {
		$v{'c_openmp'} = sub {
			Algorithm::Classifier::IsolationForest->new(
				%base,
				use_c      => 1,
				use_openmp => 1
			)->fit( $base{_data} );
		};
	}
	return \%v;
} ## end sub accel_variants

# -----------------------------------------------------------------------
# 1. n_trees
# -----------------------------------------------------------------------
print "\n--- n_trees  (1000 samples, 2 features, sample_size=256) ---\n";
srand(42);
my $d1k = make_data( 1000, 2 );
for my $nt ( 10, 50, 100, 200, 500 ) {
	printf "\n  n_trees=%d\n", $nt;
	wall_cmpthese(
		-2,
		accel_variants(
			n_trees     => $nt,
			sample_size => 256,
			mode        => 'axis',
			_data       => $d1k,
		),
	);
} ## end for my $nt ( 10, 50, 100, 200, 500 )

# -----------------------------------------------------------------------
# 2. Dataset size
# -----------------------------------------------------------------------
print "\n--- dataset size  (n_trees=100, sample_size=256, 2 features) ---\n";
srand(42);
my %ds;
$ds{$_} = make_data( $_, 2 ) for ( 500, 1_000, 2_500, 5_000, 10_000 );
for my $n ( 500, 1_000, 2_500, 5_000, 10_000 ) {
	printf "\n  %d samples\n", $n;
	wall_cmpthese(
		-2,
		accel_variants(
			n_trees     => 100,
			sample_size => 256,
			mode        => 'axis',
			_data       => $ds{$n},
		),
	);
} ## end for my $n ( 500, 1_000, 2_500, 5_000, 10_000)

# -----------------------------------------------------------------------
# 3. Feature count (wide range)
# -----------------------------------------------------------------------
print "\n--- feature count  (1000 samples, n_trees=100, sample_size=256) ---\n";
srand(42);
my %dfd;
$dfd{$_} = make_data( 1000, $_ ) for ( 2, 5, 10, 20, 50 );
for my $nf ( 2, 5, 10, 20, 50 ) {
	printf "\n  %d features\n", $nf;
	wall_cmpthese(
		-2,
		accel_variants(
			n_trees     => 100,
			sample_size => 256,
			mode        => 'axis',
			_data       => $dfd{$nf},
		),
	);
} ## end for my $nf ( 2, 5, 10, 20, 50 )

# -----------------------------------------------------------------------
# 4. Feature count (fine-grained 2-10)
# -----------------------------------------------------------------------
print "\n--- feature count 2-10  (1000 samples, n_trees=100, sample_size=256) ---\n";
srand(42);
my %dfc;
$dfc{$_} = make_data( 1000, $_ ) for ( 2 .. 10 );
for my $nf ( 2 .. 10 ) {
	printf "\n  %d columns\n", $nf;
	wall_cmpthese(
		-2,
		accel_variants(
			n_trees     => 100,
			sample_size => 256,
			mode        => 'axis',
			_data       => $dfc{$nf},
		),
	);
} ## end for my $nf ( 2 .. 10 )
