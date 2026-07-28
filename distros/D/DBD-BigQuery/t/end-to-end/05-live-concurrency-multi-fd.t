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

plan tests => 5;

$ENV{GOOGLE_APPLICATION_CREDENTIALS} = $creds if $creds && -f $creds;

my $dbh = DBI->connect("dbi:BigQuery:project=$project_id;dataset=$dataset_id", '', '', { RaiseError => 1 });

my $sth1 = $dbh->prepare('SELECT 100 AS c1', { Async => 1 });
my $sth2 = $dbh->prepare('SELECT 200 AS c2', { Async => 1 });

is($sth1->execute(), '0E0', 'sth1 non-blocking execute returned 0E0');
is($sth2->execute(), '0E0', 'sth2 non-blocking execute returned 0E0');

my @active = ($sth1, $sth2);
my %results;

while (@active) {
    my @next_active;
    for my $sth (@active) {
        if ($sth->FETCH('AsyncWantRead')) {
            if ($sth->async_read_ready()) {
                my $row = $sth->fetch_async_row();
                $results{$sth} = $row->[0] if $row;
            } else {
                push @next_active, $sth;
            }
        }
    }
    @active = @next_active;
}

ok(defined $results{$sth1}, 'sth1 fetched result concurrently');
ok(defined $results{$sth2}, 'sth2 fetched result concurrently');
ok(!$sth1->FETCH('Active') && !$sth2->FETCH('Active'), 'Both concurrent handles finished');
