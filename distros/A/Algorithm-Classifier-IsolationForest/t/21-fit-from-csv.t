#!perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Algorithm::Classifier::IsolationForest;

sub exception (&) {    ## no critic (Subroutines::ProhibitSubroutinePrototypes)
	my $code = shift;
	my $ok   = eval { $code->(); 1 };
	return $ok ? undef : ( $@ // 'died' );
}

my $CLASS = 'Algorithm::Classifier::IsolationForest';

# Write @rows (arrayrefs, or scalars for raw lines) to a temp CSV and return
# its path.  $header, if given, is prepended as a literal first line.
sub write_csv {
	my ( $rows, $header ) = @_;
	my ( $fh,   $path )   = tempfile( SUFFIX => '.csv', UNLINK => 1 );
	print {$fh} "$header\n" if defined $header;
	for my $r (@$rows) {
		print {$fh} ( ref $r ? join( ',', map { defined $_ ? $_ : '' } @$r ) : $r ), "\n";
	}
	close $fh;
	return $path;
} ## end sub write_csv

# A reproducible dataset: a tight cluster plus a few obvious outliers.
sub make_dataset {
	srand(101);
	my ( @rows, @truth );
	for ( 1 .. 400 ) { push @rows, [ rand() * 2 - 1, rand() * 2 - 1 ]; push @truth, 0 }
	for ( 1 .. 16 ) { push @rows, [ 6 + rand(), 6 + rand() ]; push @truth, 1 }
	return ( \@rows, \@truth );
}

my @BACKENDS = ( [ 'pure-perl' => 0 ] );
push @BACKENDS, [ 'C' => 1 ]
	if $Algorithm::Classifier::IsolationForest::HAS_C;

subtest 'input validation' => sub {
	my $f = $CLASS->new( n_trees => 5, sample_size => 4, seed => 1 );

	like( exception { $f->fit_from_csv() },   qr/requires a path/, 'no path croaks' );
	like( exception { $f->fit_from_csv('') }, qr/requires a path/, 'empty path croaks' );
	like( exception { $f->fit_from_csv('/no/such/file/here.csv') }, qr/not a readable file/,
		'missing file croaks' );

	my $ragged = write_csv( [ '1,2', '3,4,5' ] );
	like( exception { $f->fit_from_csv($ragged) }, qr/columns but expected/, 'ragged rows croak' );

	my $nonnum = write_csv( [ '1,2', 'foo,4' ] );
	like( exception { $f->fit_from_csv($nonnum) }, qr/is not a number/, 'non-numeric cell croaks' );

	my $empty = write_csv( [] );
	like( exception { $f->fit_from_csv($empty) }, qr/no data rows/, 'empty file croaks' );
}; ## end 'input validation' => sub

for my $be (@BACKENDS) {
	my ( $be_name, $USE_C ) = @$be;

	subtest "[$be_name] fits and matches fit()'s ranking" => sub {
		my ( $rows, $truth ) = make_dataset();
		my $csv = write_csv($rows);

		my %args   = ( n_trees => 100, sample_size => 256, seed => 42, use_c => $USE_C );
		my $stream = $CLASS->new(%args);
		$stream->fit_from_csv($csv);

		is( scalar @{ $stream->{trees} }, 100, 'built n_trees trees' );
		is( $stream->{n_features},        2,   'pinned feature width from the CSV' );
		ok( defined $stream->{psi_used} && $stream->{psi_used} == 256, 'psi resolved from census n' );

		# The outliers should score well above the cluster.
		my $scores = $stream->score_samples($rows);
		my ( $max_norm, $min_out ) = ( 0, 1 );
		for my $i ( 0 .. $#$rows ) {
			if   ( $truth->[$i] ) { $min_out  = $scores->[$i] if $scores->[$i] < $min_out }
			else                  { $max_norm = $scores->[$i] if $scores->[$i] > $max_norm }
		}
		ok( $min_out > $max_norm, 'every outlier outscores every inlier' );

		# Ranking agreement with an in-memory fit() on the same rows: the two
		# forests differ in their RNG streams, so per-point scores near the
		# middle wobble, but the top of the ranking -- where anomalies live --
		# is stable.  Both models must rank all 16 true outliers among their 20
		# highest-scored rows.
		my $mem = $CLASS->new(%args);
		$mem->fit($rows);
		for my $model ( [ stream => $scores ], [ 'fit()' => $mem->score_samples($rows) ] ) {
			my ( $name, $s ) = @$model;
			my @top  = ( sort { $s->[$b] <=> $s->[$a] } 0 .. $#$rows )[ 0 .. 19 ];
			my $hits = grep { $truth->[$_] } @top;
			is( $hits, 16, "$name ranks all outliers in its top 20" );
		}
	}; ## end "[$be_name] fits and matches fit()'s ranking" => sub

	subtest "[$be_name] same verdicts as fit() on the same data" => sub {
		# fit_from_csv and fit build different forests (their RNG streams differ
		# -- see the pod), so their trees are not bit-identical.  What must
		# agree are the results: on well-separated data both flag the same
		# anomalies.  Tight cluster at the origin, outliers far away so both
		# rank them unambiguously above the contamination cut.
		srand(202);
		my ( @rows, @truth );
		for ( 1 .. 400 ) { push @rows, [ rand() * 2 - 1, rand() * 2 - 1 ]; push @truth, 0 }
		for ( 1 .. 16 ) { push @rows, [ 15 + rand(), 15 + rand() ]; push @truth, 1 }
		my $csv = write_csv( \@rows );

		my %args = (
			n_trees       => 100,
			sample_size   => 256,
			seed          => 42,
			contamination => 16 / scalar(@rows),
			use_c         => $USE_C,
		);
		my $stream = $CLASS->new(%args);
		$stream->fit_from_csv($csv);
		my $mem = $CLASS->new(%args);
		$mem->fit( \@rows );

		my $sp = $stream->predict( \@rows );
		my $mp = $mem->predict( \@rows );
		is_deeply( $sp, $mp,     'fit_from_csv and fit flag identical anomalies' );
		is_deeply( $sp, \@truth, 'and both flag exactly the true outliers' );
	}; ## end "[$be_name] same verdicts as fit() on the same data" => sub

	subtest "[$be_name] deterministic given seed" => sub {
		my ($rows) = make_dataset();
		my $csv    = write_csv($rows);
		my %args   = ( n_trees => 40, sample_size => 128, seed => 7, contamination => 0.05, use_c => $USE_C );

		my $a = $CLASS->new(%args);
		$a->fit_from_csv($csv);
		my $b = $CLASS->new(%args);
		$b->fit_from_csv($csv);
		is( $a->to_json, $b->to_json, 'identical model across two runs' );
	}; ## end "[$be_name] deterministic given seed" => sub

	subtest "[$be_name] contamination threshold is exact" => sub {
		my ($rows) = make_dataset();
		my $csv = write_csv($rows);

		# Against the very same forest, the streaming learner must land on the
		# identical cut the batch learner computes over all rows.
		for my $cont ( 0.01, 0.05, 0.1, 0.25, 0.5 ) {
			my $m = $CLASS->new(
				n_trees       => 60,
				sample_size   => 128,
				seed          => 5,
				contamination => $cont,
				use_c         => $USE_C,
			);
			$m->fit_from_csv($csv);
			my $streamed = $m->decision_threshold;
			ok( defined $streamed, "contamination=$cont learned a threshold" );

			delete @$m{qw(_c_nodes _c_coef_idx _c_coef_val)};
			$m->_learn_contamination_threshold($rows);
			my $batch = $m->decision_threshold;
			ok( abs( $streamed - $batch ) < 1e-12, "contamination=$cont matches batch learner" );
		} ## end for my $cont ( 0.01, 0.05, 0.1, 0.25, 0.5 )
	}; ## end "[$be_name] contamination threshold is exact" => sub

	subtest "[$be_name] tied scores across the boundary" => sub {
		# Identical rows produce identical scores, forcing a tie block straddling
		# the contamination rank -- the streaming learner's rare second pass.
		my @rows = ( ( [ 1, 1 ] ) x 40, map { [ 5 + $_ / 10, 5 + $_ / 10 ] } 1 .. 10 );
		my $csv  = write_csv( \@rows );
		my $m    = $CLASS->new(
			n_trees       => 40,
			sample_size   => 64,
			seed          => 9,
			contamination => 0.2,
			use_c         => $USE_C,
		);
		$m->fit_from_csv($csv);
		my $streamed = $m->decision_threshold;
		delete @$m{qw(_c_nodes _c_coef_idx _c_coef_val)};
		$m->_learn_contamination_threshold( \@rows );
		ok( abs( $streamed - $m->decision_threshold ) < 1e-12, 'tie-block threshold is exact' );
	}; ## end "[$be_name] tied scores across the boundary" => sub

	subtest "[$be_name] missing-value strategies" => sub {
		my @rows = ( [ 1.0, 2.0 ], [ 1.1, undef ], [ undef, 2.1 ], [ 1.2, 2.2 ], [ 1.15, 2.15 ] );
		my $csv  = write_csv( \@rows );

		# sample_size >= row count => every row (including the gaps) trains, so
		# 'die' rejects the missing cell it finds in a sampled row.
		my $die = $CLASS->new( n_trees => 8, sample_size => 8, seed => 1, missing => 'die', use_c => $USE_C );
		like( exception { $die->fit_from_csv($csv) }, qr/missing value/, "die strategy rejects gaps" );

		for my $mode (qw(zero nan impute)) {
			my $m = $CLASS->new( n_trees => 8, sample_size => 4, seed => 1, missing => $mode, use_c => $USE_C );
			is( exception { $m->fit_from_csv($csv) }, undef, "$mode strategy fits" );
			is( scalar @{ $m->{trees} },              8,     "$mode built its trees" );
			if ( $mode eq 'impute' ) {
				is( scalar @{ $m->{missing_fill} }, 2, 'impute learned a fill vector' );
			}
			my $s = $m->score_samples( [ [ 1.05, undef ], [ undef, 2.05 ] ] );
			is( scalar @$s, 2, "$mode scores rows with gaps" );
		} ## end for my $mode (qw(zero nan impute))
	}; ## end "[$be_name] missing-value strategies" => sub

	subtest "[$be_name] header option and feature_names" => sub {
		my @rows = map { [ $_, $_ + 1 ] } 1 .. 30;
		my $csv  = write_csv( \@rows, 'alpha,beta' );

		my $m = $CLASS->new( n_trees => 10, sample_size => 8, seed => 1, use_c => $USE_C );
		$m->fit_from_csv( $csv, header => 1 );
		is( $m->{n_features}, 2, 'header line skipped, width from data' );

		my $named = $CLASS->new(
			n_trees       => 10,
			sample_size   => 8,
			seed          => 1,
			feature_names => [qw(alpha beta)],
			use_c         => $USE_C,
		);
		is( exception { $named->fit_from_csv( $csv, header => 1 ) }, undef, 'matching feature_names fits' );

		my $bad = $CLASS->new(
			n_trees       => 10,
			sample_size   => 8,
			seed          => 1,
			feature_names => [qw(alpha beta gamma)],
			use_c         => $USE_C,
		);
		like(
			exception { $bad->fit_from_csv( $csv, header => 1 ) },
			qr/feature_names but CSV has/,
			'feature_names/column mismatch croaks'
		);
	}; ## end "[$be_name] header option and feature_names" => sub

	subtest "[$be_name] auto-detects a feature-name header" => sub {
		my @rows = map { [ $_, $_ + 1 ] } 1 .. 30;

		# A non-numeric first line is a header even without header => 1.
		my $csv = write_csv( \@rows, 'alpha,beta' );
		my $m   = $CLASS->new( n_trees => 10, sample_size => 8, seed => 1, use_c => $USE_C );
		$m->fit_from_csv($csv);
		is( $m->{n_features}, 2, 'non-numeric header auto-skipped' );

		# An all-numeric first line is data -- not dropped.
		my $plain = write_csv( \@rows );
		my $m2    = $CLASS->new( n_trees => 10, sample_size => 8, seed => 1, use_c => $USE_C );
		$m2->fit_from_csv($plain);
		is( $m2->{psi_used}, 8, 'numeric first line kept as data' );

		# ...unless it reproduces the stored feature_names, or header => 1.  Both
		# models carry the same feature_names, so identical JSON means the
		# auto-detected skip matched the forced one.
		my $numnames = write_csv( \@rows, '1,2' );
		my %fn       = ( n_trees => 10, sample_size => 8, seed => 1, feature_names => [qw(1 2)], use_c => $USE_C );
		my $named    = $CLASS->new(%fn);
		$named->fit_from_csv($numnames);
		my $forced = $CLASS->new(%fn);
		$forced->fit_from_csv( $numnames, header => 1 );
		is( $named->to_json, $forced->to_json, 'feature_names-matching numeric header auto-skipped' );
	}; ## end "[$be_name] auto-detects a feature-name header" => sub

	subtest "[$be_name] census defers numeric validation" => sub {
		# A bad number in a row that is never sampled or scored is not caught
		# (the census does not parse cells) -- but a sampled/scored one is.  A
		# lone junk row among many, with a tiny sub-sample, is very unlikely to
		# be drawn (the fixed seed makes this deterministic).
		my $csv = write_csv( [ ( map { "$_," . ( $_ + 1 ) } 1 .. 500 ), 'oops,5' ] );

		# No contamination + tiny sample: the junk last row is not sampled.
		my $ok = $CLASS->new( n_trees => 2, sample_size => 4, seed => 2, use_c => $USE_C );
		is( exception { $ok->fit_from_csv($csv) }, undef, 'unsampled junk row tolerated' );

		# With contamination every row is scored.  Under c_scan => 0 the scored
		# cells are validated in Perl, so the junk row is rejected.
		my $strict = $CLASS->new(
			n_trees       => 3,
			sample_size   => 4,
			seed          => 2,
			contamination => 0.1,
			use_c         => $USE_C,
		);
		like(
			exception { $strict->fit_from_csv( $csv, c_scan => 0 ) },
			qr/is not a number/,
			'scored junk row validated under c_scan => 0'
		);

		# The default c_scan (on) lets the C packer coerce the junk cell to 0.0
		# instead -- faster, and silent -- so the fit completes.
		if ($USE_C) {
			my $fast = $CLASS->new(
				n_trees       => 3,
				sample_size   => 4,
				seed          => 2,
				contamination => 0.1,
				use_c         => 1,
			);
			is( exception { $fast->fit_from_csv($csv) }, undef, 'default c_scan coerces the scored junk row' );
		} ## end if ($USE_C)
	}; ## end "[$be_name] census defers numeric validation" => sub

	subtest "[$be_name] index and streaming paths agree" => sub {
		# The default offset-index gather must produce the exact same model as
		# the streaming two-pass reader, and as the memory-guarded fallback.
		my ($rows) = make_dataset();
		my $csv    = write_csv($rows);
		my %args   = (
			n_trees       => 40,
			sample_size   => 128,
			seed          => 7,
			contamination => 0.05,
			use_c         => $USE_C,
		);

		my $index = $CLASS->new(%args);
		$index->fit_from_csv( $csv, index => 1 );
		my $stream = $CLASS->new(%args);
		$stream->fit_from_csv( $csv, index => 0 );
		is( $index->to_json, $stream->to_json, 'index path == streaming path' );

		# index_max => 1 forces the offset table over budget on the first row,
		# so the fit falls back to streaming -- same model again.
		my $fallback = $CLASS->new(%args);
		$fallback->fit_from_csv( $csv, index_max => 1 );
		is( $fallback->to_json, $stream->to_json, 'over-budget index falls back to streaming' );
	}; ## end "[$be_name] index and streaming paths agree" => sub

	subtest "[$be_name] c_scan agrees with validated scan on clean data" => sub {
		# On valid numbers the C-coerced threshold pass (c_scan => 1) must reach
		# the identical model as the Perl-validated pass (c_scan => 0).
		my ($rows) = make_dataset();
		my $csv    = write_csv($rows);
		my %args   = (
			n_trees       => 40,
			sample_size   => 128,
			seed          => 3,
			contamination => 0.05,
			use_c         => $USE_C,
		);
		my $fast = $CLASS->new(%args);
		$fast->fit_from_csv( $csv, c_scan => 1 );
		my $safe = $CLASS->new(%args);
		$safe->fit_from_csv( $csv, c_scan => 0 );
		is( $fast->to_json, $safe->to_json, 'c_scan on == c_scan off on clean data' );
	}; ## end "[$be_name] c_scan agrees with validated scan on clean data" => sub

	subtest "[$be_name] sample_size larger than the file" => sub {
		# psi clamps to n; every tree trains on the whole (tiny) file.
		my @rows = map { [ $_, $_ * 2 ] } 1 .. 5;
		my $csv  = write_csv( \@rows );
		my $m    = $CLASS->new( n_trees => 6, sample_size => 256, seed => 3, use_c => $USE_C );
		$m->fit_from_csv($csv);
		is( $m->{psi_used},                          5, 'psi clamped to the row count' );
		is( scalar @{ $m->score_samples( \@rows ) }, 5, 'scores all rows' );
	};
} ## end for my $be (@BACKENDS)

done_testing();
