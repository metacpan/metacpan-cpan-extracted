use strict;
use warnings;
use Test::More;
use DBI;
use JSON::PP;

my ($project_id, $dataset_id, $creds);

if ($ENV{BIGQUERY_PROJECT} && $ENV{BIGQUERY_DATASET}) {
    $project_id = $ENV{BIGQUERY_PROJECT};
    $dataset_id = $ENV{BIGQUERY_DATASET};
} elsif (-f 'env.json') {
    open my $fh, '<', 'env.json' or die $!;
    my $data = do { local $/; <$fh> };
    close $fh;
    my $cfg = decode_json($data);
    $project_id = $cfg->{project_id};
    $dataset_id = $cfg->{dataset_id};
    $creds      = $cfg->{credentials_file};
}

if (!$project_id || !$dataset_id) {
    plan skip_all => 'Live BigQuery credentials not configured (BIGQUERY_PROJECT/BIGQUERY_DATASET or env.json missing)';
}

plan tests => 6;

$ENV{GOOGLE_APPLICATION_CREDENTIALS} = $creds if $creds && -f $creds;

my $dbh = DBI->connect("dbi:BigQuery:project=$project_id;dataset=$dataset_id", '', '', { RaiseError => 1, AutoCommit => 1 });
ok($dbh->FETCH('AutoCommit'), 'AutoCommit default 1');

# 1. Exercise begin_work and commit
ok($dbh->begin_work(), 'begin_work succeeded');
ok(!$dbh->FETCH('AutoCommit'), 'AutoCommit disabled during transaction');
ok($dbh->commit(), 'commit succeeded');
ok($dbh->FETCH('AutoCommit'), 'AutoCommit restored after commit');

# 2. Exercise rollback
$dbh->begin_work();
ok($dbh->rollback(), 'rollback succeeded');
