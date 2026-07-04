#!perl
# 90-cli-commands.t
#
# Smoke-tests the iforest CLI subcommands by running bin/iforest in a
# subprocess against a temp model + CSV.  We chain them through a
# realistic workflow:
#
#   fit  -> info
#        -> bench
#        -> pack -> predict (packed input)
#        -> predict (raw CSV input, for regression baseline)
#
# Each subtest checks the relevant artefacts and output snippets but
# stays loose on the exact wording -- we want to catch breakage, not
# pin the formatting.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

my $bin = File::Spec->rel2abs('bin/iforest');
plan skip_all => "bin/iforest not found" unless -x $bin;

my $tmp = tempdir( CLEANUP => 1 );

# --- 1. Generate a tiny CSV training dataset ----------------------------
my $train_csv = "$tmp/train.csv";
my $query_csv = "$tmp/query.csv";
my $model     = "$tmp/model.json";
my $packed    = "$tmp/query.packed";
my $pred_csv  = "$tmp/pred.csv";
my $pred2_csv = "$tmp/pred2.csv";

{
	open my $fh, '>', $train_csv or die $!;
	# 50 inliers around the origin + 3 outliers far away (3 features).
	srand(1);
	for ( 1 .. 50 ) {
		print $fh join( ',', map { sprintf( '%.4f', rand() - 0.5 ) } 1 .. 3 ), "\n";
	}
	print $fh "8,8,8\n-7,-7,-7\n7,-7,7\n";
	close $fh;
}
{
	open my $fh, '>', $query_csv or die $!;
	# 5 inliers + 2 outliers.
	srand(2);
	for ( 1 .. 5 ) {
		print $fh join( ',', map { sprintf( '%.4f', rand() - 0.5 ) } 1 .. 3 ), "\n";
	}
	print $fh "9,9,9\n-8,-8,-8\n";
	close $fh;
}

# --- 2. fit (a known-good command) --------------------------------------
subtest 'fit produces a model' => sub {
	my $out = `$^X -Ilib $bin fit -i $train_csv -o $model -n 30 -m 16 -s 42 2>&1`;
	is( $?, 0, 'fit exits 0' );
	ok( -s $model, 'model.json was written' );
};

# --- 3. info ------------------------------------------------------------
subtest 'info dumps model metadata' => sub {
	my $out = `$^X -Ilib $bin info -m $model 2>&1`;
	is( $?, 0, 'info exits 0' );
	like( $out, qr/n_trees\s+30/,           'info reports n_trees=30' );
	like( $out, qr/n_features\s+3/,         'info reports n_features=3' );
	like( $out, qr/mode\s+axis/,            'info reports mode=axis' );
	like( $out, qr/tree_total_nodes\s+\d+/, 'info reports a tree_total_nodes count' );
};

subtest 'info --json emits parseable JSON' => sub {
	my $out = `$^X -Ilib $bin info -m $model --json 2>&1`;
	is( $?, 0, 'info --json exits 0' );
	require JSON::PP;
	my $obj = eval { JSON::PP->new->decode($out) };
	ok( !$@, 'output parses as JSON' ) or diag("error: $@");
	is( $obj->{n_trees}, 30,     'JSON n_trees matches' ) if $obj;
	is( $obj->{mode},    'axis', 'JSON mode matches' )    if $obj;
};

# --- 4. bench -----------------------------------------------------------
subtest 'bench reports per-method ops/s' => sub {
	# Short --secs so the bench finishes quickly in CI.
	my $out = `$^X -Ilib $bin bench -m $model -i $query_csv --secs 0.3 2>&1`;
	is( $?, 0, 'bench exits 0' );
	like( $out, qr/score_samples\b/,       'mentions score_samples' );
	like( $out, qr/predict\b/,             'mentions predict' );
	like( $out, qr/score_predict_split\b/, 'mentions score_predict_split' );
	like( $out, qr/path_lengths\b/,        'mentions path_lengths' );
	like( $out, qr/ops\/s/,                'has ops/s column header' );
}; ## end 'bench reports per-method ops/s' => sub

# --- 5. pack + packed predict ------------------------------------------
SKIP: {
	skip 'pack requires Inline::C backend', 4
		unless $Algorithm::Classifier::IsolationForest::HAS_C;

	subtest 'pack writes a .iforest-packed file' => sub {
		my $out = `$^X -Ilib $bin pack -m $model -i $query_csv -o $packed 2>&1`;
		is( $?, 0, 'pack exits 0' );
		ok( -s $packed, 'packed file written' );

		# Verify magic bytes.
		open my $fh, '<:raw', $packed or die $!;
		my $magic;
		read( $fh, $magic, 8 );
		close $fh;
		is( $magic, "IFPKD\0\0\0", 'magic bytes match' );
	}; ## end 'pack writes a .iforest-packed file' => sub

	subtest 'predict consumes a packed input' => sub {
		my $out = `$^X -Ilib $bin predict -m $model -i $packed -o $pred_csv 2>&1`;
		is( $?, 0, 'predict (packed input) exits 0' );
		ok( -s $pred_csv, 'output prediction file written' );

		my @lines = do { open my $fh, '<', $pred_csv; <$fh> };
		is( scalar @lines, 7, 'predict emitted one row per query point (7)' );
		like( $lines[0], qr/^[\d.eE+-]+,[01]\s*$/, 'first row matches "score,label"' );
	};

	subtest 'predict on packed input agrees with CSV input' => sub {
		# Run predict against the raw CSV too and check the labels match.
		my $out = `$^X -Ilib $bin predict -m $model -i $query_csv -o $pred2_csv 2>&1`;
		is( $?, 0, 'predict (CSV input) exits 0' );

		my @a = do { open my $fh, '<', $pred_csv;  <$fh> };
		my @b = do { open my $fh, '<', $pred2_csv; <$fh> };
		is( scalar @a, scalar @b, 'same row count' );

		my $diffs = 0;
		for my $i ( 0 .. $#a ) {
			chomp( my $la = $a[$i] );
			chomp( my $lb = $b[$i] );
			my ( $sa, $ya ) = split /,/, $la;
			my ( $sb, $yb ) = split /,/, $lb;
			$diffs++ if abs( $sa - $sb ) > 1e-9;
			$diffs++ if $ya != $yb;
		}
		is( $diffs, 0, 'packed-input scores and labels match CSV-input output' );
	}; ## end 'predict on packed input agrees with CSV input' => sub

	subtest 'predict with -d works on packed input' => sub {
		my $out = `$^X -Ilib $bin predict -m $model -i $packed -d 2>&1`;
		is( $?, 0, 'predict -d (packed) exits 0' );
		my @lines = split /\n/, $out;
		is( scalar @lines, 7, 'one row per query point' );
		my $first = $lines[0];
		my @f     = split /,/, $first;
		is( scalar @f, 5, '-d output has 3 features + score + label (5 columns)' );
	};
} ## end SKIP:

# Ensure the module's HAS_C flag was probed before any SKIP block.
BEGIN { require Algorithm::Classifier::IsolationForest; }

done_testing;
