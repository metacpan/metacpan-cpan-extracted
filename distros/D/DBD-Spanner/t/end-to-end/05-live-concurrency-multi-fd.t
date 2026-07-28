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

plan tests => 5;

$ENV{GOOGLE_APPLICATION_CREDENTIALS} = $creds if $creds && -f $creds;

my $dbh = DBI->connect("dbi:Spanner:$db_path", '', '', { RaiseError => 1 });

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
