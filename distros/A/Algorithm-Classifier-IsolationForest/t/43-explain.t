#!perl
use strict;
use warnings;
use Test::More;
use List::Util qw(sum);
use File::Temp qw(tempdir);

use Algorithm::Classifier::IsolationForest;
use Algorithm::Classifier::IsolationForest::Online;

my $CLASS  = 'Algorithm::Classifier::IsolationForest';
my $ONLINE = 'Algorithm::Classifier::IsolationForest::Online';

# Run against the pure-Perl backend always, and against C when it compiled.
my @BACKENDS = ( [ 'pure-perl' => 0 ] );
push @BACKENDS, [ 'C' => 1 ]
	if $Algorithm::Classifier::IsolationForest::HAS_C;

# Deterministic 3-feature data: features 0 and 1 sweep a dense grid in
# [-1, 1], feature 2 cycles 15 distinct values in the same range.  The
# planted outlier is normal in features 0 and 1 (dead centre) and wildly
# displaced in feature 2 only -- so any correct attribution method must
# rank feature 2 first for it.
my @inliers;
for my $i ( -7 .. 7 ) {
	for my $j ( -7 .. 7 ) {
		push @inliers, [ $i / 7, $j / 7, ( ( $i * 3 + $j ) % 15 ) / 7 - 1 ];
	}
}
my $outlier = [ 0, 0, 9 ];

# The structural invariants every explanation must satisfy, whatever the
# method or model that produced it.
sub check_explanation_shape {
	my ( $e, $nf, $label ) = @_;
	ok( ref $e eq 'HASH' && ref $e->{features} eq 'ARRAY', "$label: explanation is a hashref with a features list" );
	is( scalar @{ $e->{features} }, $nf, "$label: one entry per feature" );
	ok( $e->{score} > 0 && $e->{score} <= 1, "$label: score is in (0, 1]" );
	my $sorted = 1;
	for my $k ( 1 .. $#{ $e->{features} } ) {
		$sorted = 0 if $e->{features}[$k]{weight} > $e->{features}[ $k - 1 ]{weight};
	}
	ok( $sorted, "$label: features sorted by descending weight" );
	for my $f ( @{ $e->{features} } ) {
		ok( $f->{weight} >= 0 && $f->{weight} <= 1, "$label: weight of feature $f->{index} is in [0, 1]" );
	}
} ## end sub check_explanation_shape

for my $be (@BACKENDS) {
	my ( $be_name, $USE_C ) = @$be;

	subtest "[$be_name] axis mode: both methods pin the displaced feature" => sub {
		my $f = $CLASS->new(
			n_trees     => 100,
			sample_size => 128,
			seed        => 42,
			use_c       => $USE_C,
		);
		$f->fit( [ @inliers, $outlier ] );

		ok( ref $f->{feature_baselines} eq 'ARRAY' && @{ $f->{feature_baselines} } == 3,
			'fit() stored per-feature baselines' );
		cmp_ok( abs( $f->{feature_baselines}[0] ), '<=', 0.2, 'feature 0 baseline is near the data centre' );

		# Ablation's counterfactual is expected to be near-decisive;
		# path credit is inherently noisier (every walk crosses random
		# splits too), so it only has to beat the uniform 1/3 clearly.
		my %dominance_bar = ( path => 0.4, ablation => 0.5 );
		for my $method (qw(path ablation)) {
			my $e = $f->explain_samples( [$outlier], method => $method )->[0];
			check_explanation_shape( $e, 3, $method );
			is( $e->{method},             $method, "$method: method is echoed back" );
			is( $e->{features}[0]{index}, 2,       "$method: displaced feature ranks first" );
			cmp_ok( $e->{features}[0]{weight},
				'>', $dominance_bar{$method}, "$method: displaced feature carries the most weight" );
			is( $e->{features}[0]{name}, undef, "$method: name is undef without feature_names" );
			my $sum = sum( map { $_->{weight} } @{ $e->{features} } );
			cmp_ok( abs( 1 - $sum ), '<', 1e-9, "$method: weights sum to 1" );
		} ## end for my $method (qw(path ablation))

		is( $f->explain_samples( [$outlier] )->[0]{method}, 'ablation', 'ablation is the default method' );

		# The reported score must be exactly what score_samples returns.
		my $score = $f->score_samples( [$outlier] )->[0];
		is( $f->explain_samples( [$outlier], method => 'path' )->[0]{score},
			$score, 'path: score matches score_samples' );
		is( $f->explain_samples( [$outlier], method => 'ablation' )->[0]{score},
			$score, 'ablation: score matches score_samples' );

		# Ablation extras: the top feature's substitution de-anomalises the
		# sample, and the entry names the values involved.
		my $top = $f->explain_samples( [$outlier], method => 'ablation' )->[0]{features}[0];
		cmp_ok( $top->{delta}, '>', 0.1, 'ablation: substituting the culprit drops the score substantially' );
		is( $top->{value}, 9, 'ablation: value is the sample\'s own' );
		cmp_ok( abs( $top->{baseline} ), '<=', 1, 'ablation: baseline is a normal value for the feature' );

		# Option validation.
		eval { $f->explain_samples( [$outlier], method => 'voodoo' ) };
		like( $@, qr/method must be 'path' or 'ablation'/, 'unknown method croaks' );
		eval { $f->explain_samples( [$outlier], frobnicate => 1 ) };
		like( $@, qr/unknown option/, 'unknown option croaks' );
	}; ## end "[$be_name] axis mode: both methods pin the displaced feature" => sub

	subtest "[$be_name] extended mode: both methods pin the displaced feature" => sub {
		my $f = $CLASS->new(
			n_trees     => 100,
			sample_size => 128,
			mode        => 'extended',
			seed        => 7,
			use_c       => $USE_C,
		);
		$f->fit( [ @inliers, $outlier ] );

		for my $method (qw(path ablation)) {
			my $e = $f->explain_samples( [$outlier], method => $method )->[0];
			check_explanation_shape( $e, 3, "extended/$method" );
			is( $e->{features}[0]{index}, 2, "extended/$method: displaced feature ranks first" );
		}
	}; ## end "[$be_name] extended mode: both methods pin the displaced feature" => sub
} ## end for my $be (@BACKENDS)

subtest 'path explanations are backend-independent' => sub {
	plan skip_all => 'C backend not available'
		unless $Algorithm::Classifier::IsolationForest::HAS_C;

	my %args = ( n_trees => 50, sample_size => 128, seed => 42 );
	my $perl = $CLASS->new( %args, use_c => 0 );
	my $c    = $CLASS->new( %args, use_c => 1 );
	$perl->fit( [ @inliers, $outlier ] );
	$c->fit( [ @inliers, $outlier ] );

	is_deeply( $perl->{feature_baselines}, $c->{feature_baselines}, 'baselines identical across backends' );

	for my $method (qw(path ablation)) {
		my $ep = $perl->explain_samples( [$outlier], method => $method )->[0];
		my $ec = $c->explain_samples( [$outlier], method => $method )->[0];
		is_deeply(
			[ map { [ $_->{index}, sprintf( '%.12g', $_->{weight} ) ] } @{ $ep->{features} } ],
			[ map { [ $_->{index}, sprintf( '%.12g', $_->{weight} ) ] } @{ $ec->{features} } ],
			"$method weights identical across backends (same seed, bit-identical trees)"
		);
	}
}; ## end 'path explanations are backend-independent' => sub

subtest 'ablation explains outliers the model never trained on' => sub {

	# The primary production shape: fit on clean data, score new samples,
	# explain the flagged ones.  Walk-based attribution degrades here (no
	# tree contains an isolating cut for a point it never saw -- that is
	# WHY ablation is the default); the counterfactual still nails it.
	my $f = $CLASS->new( n_trees => 100, sample_size => 128, seed => 42 );
	$f->fit( \@inliers );

	my $e = $f->explain_samples( [$outlier] )->[0];
	check_explanation_shape( $e, 3, 'unseen/ablation' );
	is( $e->{features}[0]{index}, 2, 'unseen outlier: displaced feature ranks first' );
	cmp_ok( $e->{features}[0]{weight}, '>', 0.5, 'unseen outlier: displaced feature dominates' );
}; ## end 'ablation explains outliers the model never trained on' => sub

subtest 'tagged explanation carries feature names' => sub {
	my $f = $CLASS->new(
		n_trees       => 50,
		sample_size   => 128,
		seed          => 42,
		feature_names => [qw(x y z)],
	);
	$f->fit( [ @inliers, $outlier ] );

	for my $method (qw(path ablation)) {
		my $e = $f->explain_sample_tagged( { x => 0, y => 0, z => 9 }, method => $method );
		is( $e->{features}[0]{name}, 'z', "$method: top feature is named" );
	}
}; ## end 'tagged explanation carries feature names' => sub

subtest 'persistence round-trips baselines and explanations' => sub {
	my $f = $CLASS->new( n_trees => 50, sample_size => 128, seed => 42 );
	$f->fit( [ @inliers, $outlier ] );

	my $loaded = $CLASS->from_json( $f->to_json );
	is_deeply( $loaded->{feature_baselines}, $f->{feature_baselines}, 'feature_baselines survive save/load' );

	my $before = $f->explain_samples( [$outlier], method => 'ablation' )->[0];
	my $after  = $loaded->explain_samples( [$outlier], method => 'ablation' )->[0];
	is( $after->{features}[0]{index}, $before->{features}[0]{index}, 'loaded model names the same culprit' );
	cmp_ok( abs( $after->{features}[0]{delta} - $before->{features}[0]{delta} ),
		'<', 1e-9, 'loaded model computes the same delta' );
}; ## end 'persistence round-trips baselines and explanations' => sub

subtest 'models without baselines: croak, or fall back to the impute fill' => sub {
	my $f = $CLASS->new( n_trees => 50, sample_size => 128, seed => 42 );
	$f->fit( [ @inliers, $outlier ] );

	# Simulate a model saved before baseline support.
	delete $f->{feature_baselines};
	eval { $f->explain_samples( [$outlier], method => 'ablation' ) };
	like( $@, qr/no stored feature baselines/, 'ablation croaks without baselines' );
	ok( eval { $f->explain_samples( [$outlier], method => 'path' ); 1 }, 'path still works without baselines' );

	# An old impute model has a fill vector to fall back to.
	my $g = $CLASS->new( n_trees => 50, sample_size => 128, seed => 42, missing => 'impute' );
	$g->fit( [ @inliers, $outlier ] );
	delete $g->{feature_baselines};
	my $e = $g->explain_samples( [$outlier], method => 'ablation' )->[0];
	is( $e->{features}[0]{index}, 2, 'ablation falls back to missing_fill on old impute models' );
}; ## end 'models without baselines: croak, or fall back to the impute fill' => sub

subtest 'missing values: explaining a row with undef cells' => sub {
	my @data = map { [@$_] } @inliers;
	$data[5][1] = undef;    # a hole in the training data
	my $f = $CLASS->new( n_trees => 50, sample_size => 128, seed => 42, missing => 'nan' );
	$f->fit( [ @data, $outlier ] );

	for my $method (qw(path ablation)) {
		my $e = $f->explain_samples( [ [ undef, 0, 9 ] ], method => $method )->[0];
		check_explanation_shape( $e, 3, "nan/$method" );
		is( $e->{features}[0]{index}, 2, "nan/$method: displaced feature still ranks first with an undef cell" );
	}
}; ## end 'missing values: explaining a row with undef cells' => sub

subtest 'majority voting: explanations follow vote-fraction semantics' => sub {
	my $f = $CLASS->new( n_trees => 100, sample_size => 128, seed => 42 );
	$f->fit( [ @inliers, $outlier ] );
	$f->set_voting('majority');

	my $score = $f->score_samples( [$outlier] )->[0];
	for my $method (qw(path ablation)) {
		my $e = $f->explain_samples( [$outlier], method => $method )->[0];
		is( $e->{score},              $score, "majority/$method: score is the vote fraction" );
		is( $e->{features}[0]{index}, 2,      "majority/$method: displaced feature ranks first" );
	}
}; ## end 'majority voting: explanations follow vote-fraction semantics' => sub

subtest 'fit_from_csv learns baselines too' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	my $csv = "$dir/train.csv";
	open my $fh, '>', $csv or die "cannot write $csv: $!";
	print $fh join( ',', @$_ ) . "\n" for @inliers, $outlier;
	close $fh;

	my $f = $CLASS->new( n_trees => 50, sample_size => 128, seed => 42 );
	$f->fit_from_csv($csv);

	ok( ref $f->{feature_baselines} eq 'ARRAY' && @{ $f->{feature_baselines} } == 3,
		'fit_from_csv stored baselines' );
	my $e = $f->explain_samples( [$outlier], method => 'ablation' )->[0];
	is( $e->{features}[0]{index}, 2, 'ablation works on a CSV-fitted model' );
}; ## end 'fit_from_csv learns baselines too' => sub

subtest 'online model explains streams' => sub {
	my $oif = $ONLINE->new(
		n_trees          => 50,
		window_size      => 512,
		max_leaf_samples => 16,
		seed             => 42,
	);
	$oif->learn( [@inliers] );

	# Both methods return well-formed explanations; only ablation is
	# asserted to rank correctly -- online trees are shallow and the
	# outlier was never learned, so path attribution is coarse there by
	# design (see the POD).
	for my $method (qw(path ablation)) {
		my $e = $oif->explain_samples( [$outlier], method => $method )->[0];
		check_explanation_shape( $e, 3, "online/$method" );
	}
	my $e = $oif->explain_samples( [$outlier] )->[0];
	is( $e->{method},             'ablation', 'online default method is ablation' );
	is( $e->{features}[0]{index}, 2,          'online ablation: displaced feature ranks first' );

	my $tagged_model = $ONLINE->new(
		n_trees          => 50,
		window_size      => 512,
		max_leaf_samples => 16,
		seed             => 42,
		feature_names    => [qw(x y z)],
	);
	$tagged_model->learn( [@inliers] );
	my $et = $tagged_model->explain_sample_tagged( { x => 0, y => 0, z => 9 } );
	is( $et->{features}[0]{name}, 'z', 'online tagged explanation names the culprit' );

	# A windowless model retains no data to take medians of.
	my $unbounded = $ONLINE->new(
		n_trees          => 50,
		window_size      => 0,
		max_leaf_samples => 16,
		seed             => 42,
	);
	$unbounded->learn( [@inliers] );
	eval { $unbounded->explain_samples( [$outlier] ) };
	like( $@, qr/retained window/, 'windowless online model croaks on ablation (the default)' );
	ok( eval { $unbounded->explain_samples( [$outlier], method => 'path' ); 1 },
		'windowless online model still explains via path' );
}; ## end 'online model explains streams' => sub

done_testing;
