#!perl
# 35-online-accel.t
#
# C-accelerated scoring and learning for the Online Isolation Forest.
# Scoring reuses the parent's Inline::C scorer by lazily packing the
# mutable trees into the parent's node layout; learning runs the
# per-tree insert/forget walks in C against the live trees with the
# same RNG draw order as pure Perl.  The contract to test is the same
# one the parent keeps: use_c changes speed, never results.
#
#   * every scoring method returns bit-identical values with use_c on
#     and off (including undef cells and learned contamination cutoffs)
#   * mutating the model (learn, and window eviction/unlearn) drops the
#     packed snapshot -- the next C-path call must reflect the new trees
#   * OpenMP on/off does not change results
#   * a reloaded model (which defaults to use_c) scores identically
#   * learning under the same seed and stream builds byte-identical
#     models whether use_c is on or off, across every learn code path
#     (eviction/collapse, growth modes, subsampling, missing => zero)
#
# Skipped entirely when the parent's C backend did not compile.  The
# learn-parity subtests additionally skip when the loaded C object
# predates the online learn accelerators (older prebuilt) or on
# wide-NV perls.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Config     ();

use Algorithm::Classifier::IsolationForest         ();
use Algorithm::Classifier::IsolationForest::Online ();

plan skip_all => 'Inline::C backend not available'
	unless $Algorithm::Classifier::IsolationForest::HAS_C;

my $class = 'Algorithm::Classifier::IsolationForest::Online';

use constant PI => 3.14159265358979;

sub gaussian {
	my ( $mu, $sigma ) = @_;
	my $u1 = rand() || 1e-12;
	my $u2 = rand();
	return $mu + $sigma * sqrt( -2 * log($u1) ) * cos( 2 * PI * $u2 );
}

sub cluster {
	my ( $n, $mu ) = @_;
	return [ map { [ gaussian( $mu, 1 ), gaussian( $mu, 1 ) ] } 1 .. $n ];
}

# One learned model; parity is checked by flipping the accel knobs
# between calls, which cannot change the trees (scoring never mutates).
sub make_model {
	srand(7);
	my $m = $class->new(
		seed             => 42,
		n_trees          => 50,
		window_size      => 256,
		max_leaf_samples => 16,
		contamination    => 0.05,
	);
	$m->learn( cluster( 400, 0 ) );
	return $m;
} ## end sub make_model

# The eval battery: inliers, outliers, and a row with an undef cell
# (scoring maps undef to 0 on both backends).
my @eval = ( [ 0, 0 ], [ 8, 8 ], [ 0.5, -0.3 ], [ undef, 2 ], [ -7, 7 ] );

sub with_knobs {
	my ( $m, $use_c, $use_openmp, $code ) = @_;
	local $m->{_use_c}      = $use_c;
	local $m->{_use_openmp} = ( $use_openmp && $Algorithm::Classifier::IsolationForest::HAS_OPENMP ) ? 1 : 0;
	return $code->();
}

subtest 'constructor knobs clamp like the parent' => sub {
	my $on = $class->new( use_c => 1 );
	is( $on->{_use_c}, 1, 'use_c => 1 sticks when the backend compiled' );

	my $off = $class->new( use_c => 0 );
	is( $off->{_use_c},      0, 'use_c => 0 forces pure Perl' );
	is( $off->{_use_openmp}, 0, 'use_openmp is clamped off without use_c' );

	my $omp_only = $class->new( use_c => 0, use_openmp => 1 );
	is( $omp_only->{_use_openmp}, 0, 'use_openmp => 1 is still clamped off without use_c' );
}; ## end 'constructor knobs clamp like the parent' => sub

subtest 'scoring parity: C vs pure Perl' => sub {
	my $m = make_model();

	# Prime the learned contamination threshold on the Perl path so both
	# backends label against the identical cutoff.
	with_knobs( $m, 0, 0, sub { $m->predict( \@eval ) } );

	my %perl = with_knobs(
		$m, 0, 0,
		sub {
			my ( $s, $l ) = $m->score_predict_split( \@eval );
			return (
				scores => $m->score_samples( \@eval ),
				depths => $m->path_lengths( \@eval ),
				labels => $m->predict( \@eval ),
				pairs  => $m->score_predict_samples( \@eval ),
				split  => [ $s, $l ],
			);
		}
	);
	my %c = with_knobs(
		$m, 1, 0,
		sub {
			my ( $s, $l ) = $m->score_predict_split( \@eval );
			return (
				scores => $m->score_samples( \@eval ),
				depths => $m->path_lengths( \@eval ),
				labels => $m->predict( \@eval ),
				pairs  => $m->score_predict_samples( \@eval ),
				split  => [ $s, $l ],
			);
		}
	);

	for my $i ( 0 .. $#eval ) {
		cmp_ok( $c{scores}[$i], '==', $perl{scores}[$i], "score_samples row $i identical" );
		cmp_ok( $c{depths}[$i], '==', $perl{depths}[$i], "path_lengths row $i identical" );
		is( $c{labels}[$i], $perl{labels}[$i], "predict row $i identical" );
		cmp_ok( $c{pairs}[$i][0], '==', $perl{pairs}[$i][0], "score_predict score row $i identical" );
		is( $c{pairs}[$i][1], $perl{pairs}[$i][1], "score_predict label row $i identical" );
		cmp_ok( $c{split}[0][$i], '==', $perl{split}[0][$i], "split score row $i identical" );
		is( $c{split}[1][$i], $perl{split}[1][$i], "split label row $i identical" );
	}
}; ## end 'scoring parity: C vs pure Perl' => sub

subtest 'explicit and edge thresholds agree' => sub {
	my $m = make_model();
	for my $thr ( 0.2, 0.5, 0.9, 1.5 ) {    # 1.5 exercises the non-fast-path fallback
		my $perl = with_knobs( $m, 0, 0, sub { $m->predict( \@eval, $thr ) } );
		my $c    = with_knobs( $m, 1, 0, sub { $m->predict( \@eval, $thr ) } );
		is_deeply( $c, $perl, "predict labels identical at threshold $thr" );
	}
};

subtest 'mutation invalidates the packed snapshot' => sub {
	my $m = make_model();

	my $before = with_knobs( $m, 1, 0, sub { $m->score_samples( \@eval ) } );
	ok( $m->{_c_nodes}, 'C snapshot exists after a C-path scoring call' );

	# Learn a drifted cluster; the stream length also forces window
	# evictions, so both learn and unlearn mutations are in play.
	srand(8);
	$m->learn( cluster( 300, 3 ) );
	ok( !$m->{_c_nodes}, 'snapshot dropped by learning' );

	my $c_after    = with_knobs( $m, 1, 0, sub { $m->score_samples( \@eval ) } );
	my $perl_after = with_knobs( $m, 0, 0, sub { $m->score_samples( \@eval ) } );
	for my $i ( 0 .. $#eval ) {
		cmp_ok( $c_after->[$i], '==', $perl_after->[$i], "post-mutation row $i matches fresh pure Perl" );
	}
	isnt( $c_after->[0], $before->[0], 'and the scores really did move with the drift' );
}; ## end 'mutation invalidates the packed snapshot' => sub

SKIP: {
	skip 'OpenMP not linked in', 1
		unless $Algorithm::Classifier::IsolationForest::HAS_OPENMP;

	subtest 'OpenMP on/off parity' => sub {
		my $m      = make_model();
		my $serial = with_knobs( $m, 1, 0, sub { $m->score_samples( \@eval ) } );
		my $omp    = with_knobs( $m, 1, 1, sub { $m->score_samples( \@eval ) } );
		for my $i ( 0 .. $#eval ) {
			cmp_ok( $omp->[$i], '==', $serial->[$i], "row $i identical with OpenMP" );
		}
	};
} ## end SKIP:

subtest 'reloaded models score identically through the C path' => sub {
	my $dir  = tempdir( CLEANUP => 1 );
	my $m    = make_model();
	my $path = "$dir/oiforest_model.json";
	$m->save($path);

	my $re = $class->load($path);
	is( $re->{_use_c}, 1, 'loaded model defaults to the C backend' );

	my $c    = $re->score_samples( \@eval );
	my $perl = with_knobs( $re, 0, 0, sub { $re->score_samples( \@eval ) } );
	for my $i ( 0 .. $#eval ) {
		cmp_ok( $c->[$i], '==', $perl->[$i], "reloaded row $i identical across backends" );
	}
}; ## end 'reloaded models score identically through the C path' => sub

subtest 'score_learn is knob-independent' => sub {
	plan skip_all => 'cross-backend bit-parity is guaranteed on double-NV perls only'
		if Algorithm::Classifier::IsolationForest::Online::_HAS_ONLINE_XS
		&& $Config::Config{nvsize} != 8;

	# Two models with the same seed and stream must produce identical
	# trees -- and therefore identical prequential scores -- regardless
	# of use_c: the C learn path consumes the RNG in the same order the
	# pure-Perl one does.
	my @out;
	for my $use_c ( 0, 1 ) {
		srand(9);
		my $m = $class->new(
			seed             => 11,
			n_trees          => 20,
			window_size      => 128,
			max_leaf_samples => 16,
			use_c            => $use_c,
		);
		push @out, [ @{ $m->score_learn( cluster( 300, 0 ) ) }[ 250 .. 299 ] ];
	} ## end for my $use_c ( 0, 1 )
	is_deeply( $out[1], $out[0], 'prequential scores identical with use_c on and off' );
}; ## end 'score_learn is knob-independent' => sub

subtest 'learning parity: identical trees across backends' => sub {
	plan skip_all => 'online learn XS absent from the loaded C object '
		. '(older prebuilt; rebuild or set IF_RUNTIME_BUILD=1)'
		unless Algorithm::Classifier::IsolationForest::Online::_HAS_ONLINE_XS;
	plan skip_all => 'tree bit-parity is guaranteed on double-NV perls only'
		unless $Config::Config{nvsize} == 8;

	# Same seed + same stream through both backends; the model JSON --
	# every split value, count, and bounding box, plus the window --
	# must be byte-identical.  Each config exercises a different learn
	# code path: eviction/collapse, fixed growth, the subsample gate's
	# extra draws, no-window operation, deeper trees, and undef cells
	# under missing => 'zero'.
	my @configs = (
		[ 'defaults + eviction', {} ],
		[ 'growth fixed',        { growth      => 'fixed' } ],
		[ 'subsample 0.7',       { subsample   => 0.7 } ],
		[ 'unbounded window',    { window_size => 0,   max_leaf_samples => 8 } ],
		[ 'deeper trees',        { window_size => 512, max_leaf_samples => 32 } ],
		[ 'missing => zero',     { missing     => 'zero' } ],
	);

	for my $cfg (@configs) {
		my ( $label, $opts ) = @$cfg;
		my @snap;
		for my $use_c ( 0, 1 ) {
			srand(21);
			my $m = $class->new(
				seed             => 77,
				n_trees          => 15,
				window_size      => 128,
				max_leaf_samples => 16,
				use_c            => $use_c,
				%$opts,
			);
			my $rows = cluster( 400, 0 );
			if ( ( $opts->{missing} || '' ) eq 'zero' ) {

				# Punch undef holes so the zero-fill path is what gets
				# learned.
				$rows->[$_][ $_ % 2 ] = undef for grep { !( $_ % 7 ) } 0 .. $#$rows;
			}
			$m->learn($rows);
			my $scores = $m->score_learn( cluster( 50, 2 ) );
			push @snap, [ $m->to_json, join( ',', @$scores ) ];
		} ## end for my $use_c ( 0, 1 )
		is( $snap[1][0], $snap[0][0], "$label: identical model JSON across backends" );
		is( $snap[1][1], $snap[0][1], "$label: identical prequential scores across backends" );
	} ## end for my $cfg (@configs)
}; ## end 'learning parity: identical trees across backends' => sub

done_testing;
