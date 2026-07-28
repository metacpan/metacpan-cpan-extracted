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

plan tests => 4;

$ENV{GOOGLE_APPLICATION_CREDENTIALS} = $creds if $creds && -f $creds;

my $dbh = DBI->connect("dbi:Spanner:$db_path", '', '', { RaiseError => 1 });

my $sth_ins = $dbh->prepare('INSERT INTO e2e_test (id, val) VALUES (?, ?)');
ok($sth_ins->execute(999, 'e2e_live_test'), 'Live DML INSERT executed');

my $sth_sel = $dbh->prepare('SELECT val FROM e2e_test WHERE id = ?');
$sth_sel->execute(999);
my $row = $sth_sel->fetchrow_arrayref();
is($row->[0], 'e2e_live_test', 'Live DML SELECT fetched inserted row');

my $sth_del = $dbh->prepare('DELETE FROM e2e_test WHERE id = ?');
ok($sth_del->execute(999), 'Live DML DELETE executed');

ok($dbh->ping(), 'Live connection remains healthy after DML');
