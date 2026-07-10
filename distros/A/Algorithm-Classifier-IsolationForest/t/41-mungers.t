#!perl
# 41-mungers.t
#
# Optional Algorithm::ToNumberMunger integration: a model can carry a
# declarative munger spec that turns raw tagged values into numbers, with
# the spec saved in the model JSON so a loaded model munges scoring input
# exactly as it did training input.  Covers constructor validation, the
# tagged-method plan path (batch and Online), fit_tagged / learn_tagged
# batches, positional munge_rows, expanding mungers, and persistence --
# including the lazy plan recompile after from_json and the croak on an
# unknown munger name.
#
# Skipped entirely when Algorithm::ToNumberMunger is not installed (it is
# an optional dependency).

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Algorithm::Classifier::IsolationForest         ();
use Algorithm::Classifier::IsolationForest::Online ();

plan skip_all => 'Algorithm::ToNumberMunger is not installed'
	unless eval { require Algorithm::ToNumberMunger; 1 };

my $batch_class  = 'Algorithm::Classifier::IsolationForest';
my $online_class = 'Algorithm::Classifier::IsolationForest::Online';

# A realistic little spec: an enum, a derived length, a derived entropy
# (the latter two reading source fields that are not tags), and a raw
# passthrough column (bytes) with no munger at all.
my @TAGS = qw(method path_len host_entropy bytes);

sub mungers {
	return {
		method       => { munger => 'http_method_enum', default => -1 },
		path_len     => { munger => 'length',           from    => 'path' },
		host_entropy => { munger => 'entropy',          from    => 'host' },
	};
}

# Raw tagged rows: mostly boring GETs with enough continuous spread
# (varying path lengths, a handful of hosts, noisy byte counts) that the
# trees have something real to split on.
sub raw_rows {
	my ($n)     = @_;
	my @methods = qw(GET GET GET POST HEAD);
	my @hosts   = qw(www.example.com api.example.com cdn.example.org static.example.net);
	my @rows;
	for my $i ( 1 .. $n ) {
		push @rows,
			{
				method => $methods[ $i % 5 ],
				path   => '/' . ( 'p' x ( 3 + $i % 20 ) ) . '.html',
				host   => $hosts[ $i % 4 ],
				bytes  => 500 + int( rand(400) ),
			};
	}
	return \@rows;
} ## end sub raw_rows

my %WEIRD = (
	method => 'BREW',
	path   => '/' . ( 'a' x 90 ) . '.php',
	host   => 'kq3xv9z2aa11yy77.biz',
	bytes  => 60000,
);

my %NORMAL = (
	method => 'GET',
	path   => '/' . ( 'p' x 12 ) . '.html',
	host   => 'www.example.com',
	bytes  => 700,
);

subtest 'constructor validation' => sub {
	ok( !eval { $batch_class->new( mungers => mungers() ); 1 }, 'mungers without feature_names croaks' );
	like( $@, qr/feature_names/, 'error names feature_names' );

	ok( !eval { $batch_class->new( feature_names => [@TAGS], mungers => [] ); 1 }, 'non-hashref mungers croaks' );

	ok(
		!eval {
			$batch_class->new( feature_names => [@TAGS], mungers => { method => { munger => 'bogus' } } );
			1;
		},
		'unknown munger name croaks at new()'
	);
	like( $@, qr/unknown munger 'bogus'/, 'error names the munger' );

	# The Online class mirrors all of it.
	ok( !eval { $online_class->new( mungers => mungers() ); 1 }, 'Online: mungers without feature_names croaks' );
}; ## end 'constructor validation' => sub

subtest 'batch: fit_tagged and tagged scoring on raw values' => sub {
	srand(7);
	my $f = $batch_class->new(
		seed          => 42,
		n_trees       => 50,
		sample_size   => 64,
		feature_names => [@TAGS],
		mungers       => mungers(),
	);
	$f->fit_tagged( raw_rows(200) );
	is( $f->{n_features}, 4, 'fit_tagged fitted the munged width' );

	my $normal = $f->score_sample_tagged( {%NORMAL} );
	my $weird  = $f->score_sample_tagged( {%WEIRD} );
	cmp_ok( $weird, '>', $normal, 'raw anomalous row scores above a normal one' );

	# The tagged path must equal hand-munging + positional scoring.
	# munge_rows applies scalar mungers positionally: method enum on col 0,
	# length on col 1, entropy on col 2, raw passthrough on col 3.
	my $by_hand
		= $f->score_samples( $f->munge_rows( [ [ 'BREW', $WEIRD{path}, $WEIRD{host}, $WEIRD{bytes} ] ] ) );
	cmp_ok( abs( $by_hand->[0] - $weird ), '<', 1e-12, 'tagged path equals hand-munged positional path' );

	# Plan validation: a missing source field croaks, extra keys are fine.
	ok( !eval { $f->score_sample_tagged( { method => 'GET', host => 'x', bytes => 1 } ); 1 },
		'missing munger source field croaks' );
	like( $@, qr/missing value for 'path'/, 'error names the missing source' );
	ok(
		eval {
			$f->score_sample_tagged( { %NORMAL, extra_key => 'ignored' } );
			1;
		},
		'extra keys are ignored under a plan'
	) or diag $@;
}; ## end 'batch: fit_tagged and tagged scoring on raw values' => sub

subtest 'expanding munger (datetime parts/into)' => sub {
	srand(8);
	my $f = $batch_class->new(
		seed          => 1,
		n_trees       => 30,
		sample_size   => 64,
		feature_names => [ 'bytes', 'tod_sin', 'tod_cos' ],
		mungers       => {
			time_of_day => {
				munger => 'datetime',
				from   => 'stamp',
				format => '%Y-%m-%dT%H:%M:%S',
				parts  => [ 'sin_day', 'cos_day' ],
				into   => [ 'tod_sin', 'tod_cos' ],
			},
		},
	);

	# Nightly-job traffic around 03:00; the anomaly fires at 15:00.
	my @rows;
	for my $i ( 1 .. 150 ) {
		my $min = $i % 50;
		push @rows,
			{
				bytes => 500 + ( $i % 37 ),
				stamp => sprintf( '2026-07-0%dT03:%02d:00', 1 + ( $i % 7 ), $min ),
			};
	}
	$f->fit_tagged( \@rows );

	my $night = $f->score_sample_tagged( { bytes => 510, stamp => '2026-07-03T03:10:00' } );
	my $noon  = $f->score_sample_tagged( { bytes => 510, stamp => '2026-07-03T15:00:00' } );
	cmp_ok( $noon, '>', $night, 'off-schedule time scores above the usual window' );

	# Positional munging cannot express an expander.
	ok( !eval { $f->munge_rows( [ [ 1, 2, 3 ] ] ); 1 }, 'munge_rows croaks with an expanding munger' );
}; ## end 'expanding munger (datetime parts/into)' => sub

subtest 'persistence round trip (batch)' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	srand(9);
	my $f = $batch_class->new(
		seed          => 42,
		n_trees       => 40,
		sample_size   => 64,
		contamination => 0.05,
		feature_names => [@TAGS],
		mungers       => mungers(),
	);
	$f->fit_tagged( raw_rows(200) );
	my $before = $f->score_sample_tagged( {%WEIRD} );

	my $path = "$dir/munged_model.json";
	$f->save($path);

	my $re = $batch_class->load($path);
	is_deeply( $re->{mungers}, mungers(), 'munger spec survived the round trip' );
	is(
		$re->{munger_module_version},
		$Algorithm::ToNumberMunger::VERSION,
		'munger module version recorded with the model'
	);
	ok( !$re->{_munger_plan}, 'plan is not compiled at load time (lazy)' );

	my $after = $re->score_sample_tagged( {%WEIRD} );
	cmp_ok( abs( $after - $before ), '<', 1e-12, 'reloaded model munges and scores identically' );
	ok( $re->{_munger_plan}, 'plan compiled lazily on first tagged use' );

	# A spec naming a munger the installed module lacks croaks lazily,
	# with a message naming it -- the stale-module failure mode.
	my $broken = $batch_class->load($path);
	$broken->{mungers}{method}{munger} = 'bogus_from_the_future';
	ok( !eval { $broken->score_sample_tagged( {%WEIRD} ); 1 }, 'unknown munger in a loaded model croaks' );
	like( $@, qr/unknown munger 'bogus_from_the_future'/, 'error names the unknown munger' );
}; ## end 'persistence round trip (batch)' => sub

subtest 'Online: learn_tagged batches, prequential scoring, persistence' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	srand(10);
	my $m = $online_class->new(
		seed             => 42,
		n_trees          => 40,
		window_size      => 128,
		max_leaf_samples => 16,
		feature_names    => [@TAGS],
		mungers          => mungers(),
	);

	my $ret = $m->learn_tagged( raw_rows(200) );
	is( $ret,     $m,  'learn_tagged (batch form) chains' );
	is( $m->seen, 200, 'batch form learned every row' );
	$m->learn_tagged( { method => 'GET', path => '/one.html', host => 'www.example.com', bytes => 640 } );
	is( $m->seen, 201, 'single-hashref form still works' );

	my $normal = $m->score_sample_tagged( {%NORMAL} );
	my $weird  = $m->score_learn_tagged( {%WEIRD} );
	cmp_ok( $weird, '>', $normal, 'raw anomalous row scores above a normal one prequentially' );

	my $path = "$dir/oiforest_munged.json";
	$m->save($path);

	# Parent-class load dispatches AND keeps the munger spec.
	my $re = Algorithm::Classifier::IsolationForest->load($path);
	isa_ok( $re, $online_class, 'parent load() returns the online model' );
	is_deeply( $re->{mungers}, mungers(), 'munger spec survived the online round trip' );

	my $s1 = $m->score_sample_tagged( {%WEIRD} );
	my $s2 = $re->score_sample_tagged( {%WEIRD} );
	cmp_ok( abs( $s2 - $s1 ), '<', 1e-12, 'reloaded online model munges and scores identically' );
}; ## end 'Online: learn_tagged batches, prequential scoring, persistence' => sub

done_testing;
