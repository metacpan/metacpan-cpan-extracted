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

# --- 3b. info reports feature-name tags --------------------------------
subtest 'info displays tag info' => sub {
	# The baseline model was fit without -t, so it is untagged.
	my $out = `$^X -Ilib $bin info -m $model 2>&1`;
	like( $out, qr/tagged\s+0/, 'untagged model reports tagged=0' );
	unlike( $out, qr/feature_names/, 'untagged model omits the feature_names block' );

	# Fit a tagged model over the same 3-feature CSV.
	my $tagged = "$tmp/tagged.json";
	my $fit    = `$^X -Ilib $bin fit -i $train_csv -o $tagged -n 30 -m 16 -s 42 -t cpu -t mem -t disk 2>&1`;
	is( $?, 0, 'tagged fit exits 0' ) or diag($fit);

	my $t = `$^X -Ilib $bin info -m $tagged 2>&1`;
	is( $?, 0, 'info on tagged model exits 0' );
	like( $t, qr/tagged\s+1/,                     'reports tagged=1' );
	like( $t, qr/feature_names\s+cpu, mem, disk/, 'lists the joined tags' );
	like( $t, qr/\[0\]\s+cpu/,                    'lists tag [0] cpu' );
	like( $t, qr/\[1\]\s+mem/,                    'lists tag [1] mem' );
	like( $t, qr/\[2\]\s+disk/,                   'lists tag [2] disk' );

	# --json carries the same info in machine-readable form.
	my $j = `$^X -Ilib $bin info -m $tagged --json 2>&1`;
	require JSON::PP;
	my $obj = eval { JSON::PP->new->decode($j) };
	ok( !$@, 'tagged --json parses' ) or diag("error: $@");
	if ($obj) {
		is( $obj->{tagged}, 1, 'JSON tagged=1' );
		is_deeply( $obj->{feature_names}, [qw(cpu mem disk)], 'JSON feature_names matches tags' );
	}
}; ## end 'info displays tag info' => sub

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

# --- online model workflow: stream + info -------------------------------
{
	my $stream_csv = "$tmp/stream.csv";
	my $omodel     = "$tmp/online_model.json";
	my $oscores    = "$tmp/stream_scores.csv";

	{
		open my $fh, '>', $stream_csv or die $!;
		srand(3);
		for ( 1 .. 120 ) {
			print $fh join( ',', map { sprintf( '%.4f', rand() - 0.5 ) } 1 .. 3 ), "\n";
		}
		print $fh "9,9,9\n";
		close $fh;
	}

	subtest 'stream creates an online model and emits prequential scores' => sub {
		my $out = `$^X -Ilib $bin stream -i $stream_csv -m $omodel -n 20 --window 64 --eta 16 -s 42 2>&1`;
		is( $?, 0, 'stream exits 0' );
		ok( -s $omodel, 'online model was written' );
		my @lines = split /\n/, $out;
		is( scalar @lines, 121, 'one output row per input row' );
		like( $lines[-1], qr/^[\d.eE+-]+,[01]$/, 'rows match "score,label"' );
	};

	subtest 'stream resumes a saved model' => sub {
		my $out = `$^X -Ilib $bin stream -i $stream_csv -m $omodel 2>&1`;
		is( $?, 0, 'stream (resume) exits 0' );
		my @lines = split /\n/, $out;
		is( scalar @lines, 121, 'one output row per input row on resume' );
	};

	subtest 'stream --score-only does not advance the model' => sub {
		my $before = do { local ( @ARGV, $/ ) = ($omodel); <> };
		my $out    = `$^X -Ilib $bin stream --score-only -i $stream_csv -m $omodel -o $oscores 2>&1`;
		is( $?, 0, 'stream --score-only exits 0' );
		ok( -s $oscores, 'score output file written' );
		my $after = do { local ( @ARGV, $/ ) = ($omodel); <> };
		is( $after, $before, 'model file unchanged by --score-only' );
	};

	subtest 'stream --learn-only emits nothing but updates the model' => sub {
		my $before = do { local ( @ARGV, $/ ) = ($omodel); <> };
		my $out    = `$^X -Ilib $bin stream --learn-only -i $stream_csv -m $omodel 2>&1`;
		is( $?,   0,  'stream --learn-only exits 0' );
		is( $out, '', 'no score output' );
		my $after = do { local ( @ARGV, $/ ) = ($omodel); <> };
		isnt( $after, $before, 'model file advanced by --learn-only' );
	};

	subtest 'info recognises an online model' => sub {
		my $out = `$^X -Ilib $bin info -m $omodel 2>&1`;
		is( $?, 0, 'info exits 0 on an online model' );
		like( $out, qr/type\s+online/,          'info reports type=online' );
		like( $out, qr/window_size\s+64/,       'info reports window_size' );
		like( $out, qr/max_leaf_samples\s+16/,  'info reports max_leaf_samples' );
		like( $out, qr/tree_total_nodes\s+\d+/, 'info reports tree stats' );
	};

	subtest 'info --json on an online model parses' => sub {
		my $out = `$^X -Ilib $bin info -m $omodel --json 2>&1`;
		is( $?, 0, 'info --json exits 0' );
		require JSON::PP;
		my $obj = eval { JSON::PP->new->decode($out) };
		ok( !$@, 'output parses as JSON' ) or diag("error: $@");
		if ($obj) {
			is( $obj->{type},    'online', 'JSON type matches' );
			is( $obj->{n_trees}, 20,       'JSON n_trees matches' );
		}
	}; ## end 'info --json on an online model parses' => sub

	subtest 'stream refuses a batch model' => sub {
		my $out = `$^X -Ilib $bin stream -i $stream_csv -m $model 2>&1`;
		isnt( $?, 0, 'stream exits non-zero on a batch model' );
		like( $out, qr/not an online model/, 'error explains the mismatch' );
	};
}

# --- munger workflow: fit/predict/stream with raw (non-numeric) CSV -----
SKIP: {
	skip 'Algorithm::ToNumberMunger is not installed', 5
		unless eval { require Algorithm::ToNumberMunger; 1 };

	my $munger_json = "$tmp/mungers.json";
	my $raw_csv     = "$tmp/raw.csv";
	my $mmodel      = "$tmp/munged_model.json";
	my $momodel     = "$tmp/munged_online_model.json";

	{
		open my $fh, '>', $munger_json or die $!;
		print $fh '{ "method": { "munger": "http_method_enum", "default": -1 },'
			. ' "path_len": { "munger": "length", "from": "path" } }';
		close $fh;
	}
	{
		open my $fh, '>', $raw_csv or die $!;
		srand(4);
		my @methods = qw(GET GET GET POST HEAD);
		for my $i ( 1 .. 80 ) {
			printf $fh "%s,%s,%.4f\n", $methods[ $i % 5 ], '/' . ( 'p' x ( 3 + $i % 20 ) ), 500 + rand(400);
		}
		print $fh 'BREW,/' . ( 'a' x 90 ) . ",60000\n";
		close $fh;
	}

	subtest 'fit --mungers accepts raw CSV and saves the spec' => sub {
		my $out
			= `$^X -Ilib $bin fit -i $raw_csv -o $mmodel -n 30 -m 32 -s 42 -t method -t path_len -t bytes --mungers $munger_json 2>&1`;
		is( $?, 0, 'fit --mungers exits 0' ) or diag $out;
		ok( -s $mmodel, 'model written' );
		like(
			scalar(
				do { local ( @ARGV, $/ ) = ($mmodel); <> }
			),
			qr/"mungers"/,
			'model JSON carries the munger spec'
		);
	}; ## end 'fit --mungers accepts raw CSV and saves the spec' => sub

	subtest 'fit --mungers without -t is refused' => sub {
		my $out = `$^X -Ilib $bin fit -i $raw_csv -o $tmp/nope.json -w --mungers $munger_json 2>&1`;
		isnt( $?, 0, 'exits non-zero' );
		like( $out, qr/requires feature tags/, 'error explains -t is needed' );
	};

	subtest 'predict munges raw CSV against a munger-bearing model' => sub {
		my $out = `$^X -Ilib $bin predict -m $mmodel -i $raw_csv 2>&1`;
		is( $?, 0, 'predict exits 0' ) or diag $out;
		my @lines = split /\n/, $out;
		is( scalar @lines, 81, 'one output row per input row' );
		like( $lines[-1], qr/^[\d.eE+-]+,[01]$/, 'rows match "score,label"' );
	};

	subtest 'info shows the munger summary' => sub {
		my $out = `$^X -Ilib $bin info -m $mmodel 2>&1`;
		is( $?, 0, 'info exits 0' );
		like( $out, qr/mungers\s+2 configured/,        'munger count shown' );
		like( $out, qr/method\s+http_method_enum/,     'munger names listed' );
		like( $out, qr/munger_module_version\s+[\d.]/, 'module version shown' );
	};

	subtest 'stream --mungers creates and resumes a munged online model' => sub {
		my $out
			= `$^X -Ilib $bin stream -i $raw_csv -m $momodel -n 20 --window 64 --eta 16 -s 7 -t method -t path_len -t bytes --mungers $munger_json 2>&1`;
		is( $?, 0, 'stream --mungers exits 0' ) or diag $out;
		ok( -s $momodel, 'online model written' );

		# Resume: the model carries its spec, so raw CSV still works with
		# no --mungers flag.
		my $out2 = `$^X -Ilib $bin stream -i $raw_csv -m $momodel 2>&1`;
		is( $?, 0, 'resumed stream exits 0' ) or diag $out2;
		my @lines = split /\n/, $out2;
		is( scalar @lines, 81, 'one output row per input row on resume' );
	}; ## end 'stream --mungers creates and resumes a munged online model' => sub
} ## end SKIP:

# --- prototype workflow: fit/stream --prototype, proto command ----------
{
	my $bproto  = "$tmp/proto_batch.json";
	my $oproto  = "$tmp/proto_online.json";
	my $pmodel  = "$tmp/proto_model.json";
	my $pomodel = "$tmp/proto_online_model.json";

	{
		open my $fh, '>', $bproto or die $!;
		print $fh '{ "format": "Algorithm::Classifier::IsolationForest::Prototype",'
			. ' "class": "batch", "schema_version": "2026.07.08-1",'
			. ' "schema_description": "three synthetic metrics",'
			. ' "schema": { "feature_names": ["cpu", "mem", "disk"],'
			. ' "feature_descriptions": { "cpu": "cpu utilisation fraction" } },'
			. ' "params": { "n_trees": 30, "sample_size": 16 } }';
		close $fh;
	}
	{
		open my $fh, '>', $oproto or die $!;
		print $fh '{ "format": "Algorithm::Classifier::IsolationForest::Prototype",'
			. ' "class": "online", "schema_version": "s2",'
			. ' "schema_description": "online metrics stream",'
			. ' "schema": { "feature_names": ["cpu", "mem", "disk"] },'
			. ' "params": { "n_trees": 20, "window_size": 64, "max_leaf_samples": 16 } }';
		close $fh;
	}

	subtest 'fit --prototype creates a model carrying the schema metadata' => sub {
		my $out = `$^X -Ilib $bin fit --prototype $bproto -i $train_csv -o $pmodel -s 42 2>&1`;
		is( $?, 0, 'fit --prototype exits 0' ) or diag $out;
		ok( -s $pmodel, 'model written' );

		my $info = `$^X -Ilib $bin info -m $pmodel 2>&1`;
		is( $?, 0, 'info exits 0' );
		like( $info, qr/schema_version\s+2026\.07\.08-1/,              'schema_version shown, unmangled' );
		like( $info, qr/schema_description\s+three synthetic metrics/, 'schema_description shown' );
		like( $info, qr/\[0\]\s+cpu -- cpu utilisation fraction/,      'feature description beside its tag' );
		like( $info, qr/\[1\]\s+mem\s*$/m,                             'undescribed tag rendered bare' );
		like( $info, qr/n_trees\s+30/,                                 'prototype param applied' );
	}; ## end 'fit --prototype creates a model carrying the schema metadata' => sub

	subtest 'fit --prototype refusals' => sub {
		my $out = `$^X -Ilib $bin fit --prototype $bproto -t cpu -i $train_csv -p 2>&1`;
		isnt( $?, 0, 'combining --prototype with -t exits non-zero' );
		like( $out, qr/may not be combined/, 'error explains the conflict' );

		$out = `$^X -Ilib $bin fit --prototype $oproto -i $train_csv -p 2>&1`;
		isnt( $?, 0, 'an online prototype is refused by fit' );
		like( $out, qr/use `iforest stream`/, 'error points at stream' );
	};

	subtest 'stream --prototype creates an online model' => sub {
		my $out = `$^X -Ilib $bin stream --prototype $oproto -i $train_csv -m $pomodel -s 7 2>&1`;
		is( $?, 0, 'stream --prototype exits 0' ) or diag $out;
		ok( -s $pomodel, 'online model written' );

		my $info = `$^X -Ilib $bin info -m $pomodel 2>&1`;
		like( $info, qr/type\s+online/,                              'created model is online' );
		like( $info, qr/schema_version\s+s2/,                        'schema_version carried' );
		like( $info, qr/schema_description\s+online metrics stream/, 'schema_description carried' );
		like( $info, qr/window_size\s+64/,                           'prototype param applied' );

		# Resume ignores the creation knob, like the rest of them.
		my $out2 = `$^X -Ilib $bin stream --prototype $oproto -i $train_csv -m $pomodel 2>&1`;
		is( $?, 0, 'resumed stream with the flag still exits 0' ) or diag $out2;

		$out = `$^X -Ilib $bin stream --prototype $bproto -i $train_csv -m $tmp/nope_online.json 2>&1`;
		isnt( $?, 0, 'a batch prototype is refused by stream' );
		like( $out, qr/use `iforest fit`/, 'error points at fit' );
	}; ## end 'stream --prototype creates an online model' => sub

	subtest 'proto --from-model extracts a working prototype' => sub {
		my $extracted = "$tmp/extracted_proto.json";
		my $out       = `$^X -Ilib $bin proto --from-model $pmodel -o $extracted 2>&1`;
		is( $?, 0, 'proto --from-model exits 0' ) or diag $out;
		ok( -s $extracted, 'prototype file written' );

		my $check = `$^X -Ilib $bin proto --check $extracted 2>&1`;
		is( $?, 0, 'extracted prototype passes --check' ) or diag $check;
		like( $check, qr/class\s+batch/,                           'summary shows the class' );
		like( $check, qr/schema_version\s+2026\.07\.08-1/,         'summary keeps the schema_version' );
		like( $check, qr/\[0\]\s+cpu -- cpu utilisation fraction/, 'summary lists feature descriptions' );

		# The extraction closes the loop: fit a fresh model from it.
		my $refit = `$^X -Ilib $bin fit --prototype $extracted -i $train_csv -o $tmp/refit.json -s 42 2>&1`;
		is( $?, 0, 'fit from the extracted prototype exits 0' ) or diag $refit;
	}; ## end 'proto --from-model extracts a working prototype' => sub

	subtest 'proto --check rejects invalid input' => sub {
		my $bad = "$tmp/bad_proto.json";
		{
			open my $fh, '>', $bad or die $!;
			print $fh '{ "format": "Algorithm::Classifier::IsolationForest::Prototype", "class": "batch" }';
			close $fh;
		}
		my $out = `$^X -Ilib $bin proto --check $bad 2>&1`;
		isnt( $?, 0, 'invalid prototype exits non-zero' );
		like( $out, qr/is not a valid prototype/, 'error says the file is invalid' );

		$out = `$^X -Ilib $bin proto --check $bad --from-model $pmodel 2>&1`;
		isnt( $?, 0, 'combining --check and --from-model exits non-zero' );
		like( $out, qr/exactly one of/, 'error explains the exclusivity' );

		$out = `$^X -Ilib $bin proto 2>&1`;
		isnt( $?, 0, 'neither switch exits non-zero' );
	}; ## end 'proto --check rejects invalid input' => sub
}

# Ensure the module's HAS_C flag was probed before any SKIP block.
BEGIN { require Algorithm::Classifier::IsolationForest; }

done_testing;
