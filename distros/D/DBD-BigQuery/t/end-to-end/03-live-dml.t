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

plan tests => 4;

$ENV{GOOGLE_APPLICATION_CREDENTIALS} = $creds if $creds && -f $creds;

my $dbh = DBI->connect("dbi:BigQuery:project=$project_id;dataset=$dataset_id", '', '', { RaiseError => 1 });

my $sth_ins = $dbh->prepare("INSERT INTO $dataset_id.e2e_test (id, data) VALUES (?, ?)");
ok($sth_ins->execute(999, 'e2e_live_bq'), 'Live DML INSERT executed');

my $sth_sel = $dbh->prepare("SELECT data FROM $dataset_id.e2e_test WHERE id = ?");
$sth_sel->execute(999);
my $row = $sth_sel->fetchrow_arrayref();
is($row->[0], 'e2e_live_bq', 'Live DML SELECT fetched inserted row');

my $sth_del = $dbh->prepare("DELETE FROM $dataset_id.e2e_test WHERE id = ?");
ok($sth_del->execute(999), 'Live DML DELETE executed');

ok($dbh->ping(), 'Live connection remains healthy after DML');
