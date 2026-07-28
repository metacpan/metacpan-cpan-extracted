use strict;
use warnings;
use Test::More;
use DBI;
use JSON::PP;

my ($db_path, $creds);

if ($ENV{SPANNER_DATABASE_PATH}) {
    $db_path = $ENV{SPANNER_DATABASE_PATH};
} elsif (-f 'env.json') {
    open my $fh, '<', 'env.json' or die $!;
    my $data = do { local $/; <$fh> };
    close $fh;
    my $cfg = decode_json($data);
    $db_path = $cfg->{spanner_db_path};
    $creds   = $cfg->{credentials_file};
}

if (!$db_path) {
    plan skip_all => 'Live Spanner credentials not configured (SPANNER_DATABASE_PATH or env.json missing)';
}

plan tests => 6;

$ENV{GOOGLE_APPLICATION_CREDENTIALS} = $creds if $creds && -f $creds;

my $dbh = DBI->connect("dbi:Spanner:$db_path", '', '', { RaiseError => 1, AutoCommit => 1 });
ok($dbh->FETCH('AutoCommit'), 'AutoCommit default 1');

# 1. Exercise begin_work and commit
ok($dbh->begin_work(), 'begin_work succeeded');
ok(!$dbh->FETCH('AutoCommit'), 'AutoCommit disabled during transaction');
ok($dbh->commit(), 'commit succeeded');
ok($dbh->FETCH('AutoCommit'), 'AutoCommit restored after commit');

# 2. Exercise rollback
$dbh->begin_work();
ok($dbh->rollback(), 'rollback succeeded');
