#!/usr/bin/env perl
# t/alert.t -- Phase 4.3: bi-alert CLI tests

use strict;
use warnings;

use lib 'lib';

use File::Spec;
use File::Temp	qw(tempdir);
use Mojo::File;
use Mojo::JSON	qw(encode_json);
use Test::More;

# ---------------------------------------------------------------------------
# Locate the script
# ---------------------------------------------------------------------------

my $script = File::Spec->catfile('script', 'bi-alert');
plan skip_all => 'script/bi-alert not found' unless -f $script && -x $script;
plan skip_all => 'data/sales.csv not found'  unless -f 'data/sales.csv';

my $perl = $^X;

# ---------------------------------------------------------------------------
# Helper: run bi-alert and capture output + exit code
# ---------------------------------------------------------------------------

sub run_alert {
	my (@args) = @_;
	my $out = qx("$perl" "$script" @args 2>&1);
	return ($out, $? >> 8);
}

# ---------------------------------------------------------------------------
# Prepare a model_dir with a minimal saved analysis pointing at sales.csv
# ---------------------------------------------------------------------------

my $model_dir = tempdir(CLEANUP => 1);
my $data_dir  = File::Spec->rel2abs('data');

my $analysis = {
	id       => 'testalert1',
	name     => 'Alert test analysis',
	version  => 1,
	created  => time(),
	updated  => time(),
	datasets => [ { spec => "path:$data_dir/sales.csv" } ],
	visuals  => [],
};

my $analyses = { $analysis->{id} => $analysis };
Mojo::File->new($model_dir, 'analyses.json')->spurt(encode_json($analyses));

my $id = $analysis->{id};

# ---------------------------------------------------------------------------
# 1. --help exits 0 and prints usage
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert('--help');
	is($code, 0, '--help exits 0');
	like($out, qr/--analysis/i, '--help mentions --analysis');
}

# ---------------------------------------------------------------------------
# 2. Missing --analysis exits 2
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert('--model-dir', $model_dir, '--data-dir', $data_dir);
	is($code, 2, 'missing --analysis exits 2');
}

# ---------------------------------------------------------------------------
# 3. Unknown analysis id exits 2
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir,
		'--data-dir',  $data_dir,
		'--analysis',  'nosuchid',
		'--dry-run',
	);
	is($code, 2, 'unknown analysis id exits 2');
}

# ---------------------------------------------------------------------------
# 4. --dry-run prints a digest and exits 0 (no threshold) or 1 (threshold crossed)
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir,
		'--data-dir',  $data_dir,
		'--analysis',  $id,
		'--dry-run',
	);
	ok($code == 0 || $code == 1, "--dry-run exits 0 or 1 (got $code)");
	like($out, qr/\S/, '--dry-run produces output');
}

# ---------------------------------------------------------------------------
# 5. --dry-run with a threshold certainly crossed (count > 0; sales.csv has rows)
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir,
		'--data-dir',  $data_dir,
		'--analysis',  $id,
		'--threshold', 'count:gt:0',
		'--dry-run',
	);
	is($code, 1, '--dry-run with crossed threshold (count > 0) exits 1');
}

# ---------------------------------------------------------------------------
# 6. --dry-run with a threshold certainly NOT crossed (count > 1 000 000)
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir,
		'--data-dir',  $data_dir,
		'--analysis',  $id,
		'--threshold', 'count:gt:1000000',
		'--dry-run',
	);
	is($code, 0, '--dry-run with uncrossed threshold (count > 1M) exits 0');
}

done_testing;
