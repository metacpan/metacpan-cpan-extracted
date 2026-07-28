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

plan tests => 3;

$ENV{GOOGLE_APPLICATION_CREDENTIALS} = $creds if $creds && -f $creds;

my $dbh = DBI->connect("dbi:BigQuery:project=$project_id;dataset=$dataset_id", '', '', { RaiseError => 1 });
ok($dbh, 'Connected to live Cloud BigQuery dataset');
ok($dbh->ping(), 'Live ping succeeded');

my $sth = $dbh->prepare('SELECT 1 AS alive');
$sth->execute();
my $row = $sth->fetchrow_arrayref();
is($row->[0], 1, 'Fetched live SELECT 1 result');
