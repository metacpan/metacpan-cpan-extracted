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

plan tests => 3;

$ENV{GOOGLE_APPLICATION_CREDENTIALS} = $creds if $creds && -f $creds;

my $dbh = DBI->connect("dbi:Spanner:$db_path", '', '', { RaiseError => 1 });
ok($dbh, 'Connected to live Cloud Spanner instance');
ok($dbh->ping(), 'Live ping succeeded');

my $sth = $dbh->prepare('SELECT 1 AS alive');
$sth->execute();
my $row = $sth->fetchrow_arrayref();
is($row->[0], 1, 'Fetched live SELECT 1 result');
