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
my $sth = $dbh->prepare('SELECT 42 AS val', { Async => 1 });
my $rv  = $sth->execute();

is($rv, '0E0', 'Live non-blocking execute returned 0E0');
ok($sth->FETCH('AsyncWantRead'), 'AsyncWantRead active on live query');

while ($sth->FETCH('AsyncWantRead')) {
    if ($sth->async_read_ready()) {
        my $row = $sth->fetch_async_row();
        is($row->[0], 42, 'Fetched live async result row');
        last;
    }
}

ok(!$sth->FETCH('Active'), 'Live handle finished');
