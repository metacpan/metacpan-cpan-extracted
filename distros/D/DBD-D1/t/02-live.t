use strict;
use warnings;
use Test::More;

unless ($ENV{CF_ACCOUNT_ID} && $ENV{CF_D1_DATABASE_ID} && $ENV{CF_API_TOKEN}) {
    plan skip_all =>
        'Live tests skipped: set CF_ACCOUNT_ID, CF_D1_DATABASE_ID, CF_API_TOKEN to enable';
}

eval { require DBI; require DBD::D1 };
plan skip_all => "DBI or DBD::D1 not available: $@" if $@;

eval { require IO::Socket::SSL; require Net::SSLeay };
if ($@) {
    plan skip_all =>
        'Live tests skipped: install IO::Socket::SSL and Net::SSLeay first';
}

unless (HTTP::Tiny->can_ssl) {
    plan skip_all => 'Live tests skipped: HTTP::Tiny reports SSL unavailable';
}

plan tests => 10;

my $dbh = DBI->connect(
    "dbi:D1:account_id=$ENV{CF_ACCOUNT_ID};database_id=$ENV{CF_D1_DATABASE_ID}",
    undef,
    $ENV{CF_API_TOKEN},
    { RaiseError => 1, PrintError => 0 },
);
isa_ok($dbh, 'DBI::db', 'got database handle');

ok($dbh->ping, 'ping succeeds');

eval {
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS dbd_d1_test (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT    NOT NULL,
            value REAL
        )
    });
};
is($@, '', 'CREATE TABLE did not die');

my $ins = $dbh->prepare('INSERT INTO dbd_d1_test (label, value) VALUES (?, ?)');
isa_ok($ins, 'DBI::st', 'prepare returns statement handle');

my $rv = $ins->execute('alpha', 1.5);
ok($rv, 'INSERT execute returned true');
$ins->execute('beta',  2.5);
$ins->execute('gamma', 3.5);

my $sel = $dbh->prepare('SELECT label, value FROM dbd_d1_test ORDER BY id');
$sel->execute;
my $rows = $sel->fetchall_arrayref;
ok(scalar @$rows >= 3, 'fetched at least 3 rows');

$sel->execute;
my $row = $sel->fetchrow_hashref;
ok(defined $row->{label}, 'fetchrow_hashref has label key');
ok(defined $row->{value}, 'fetchrow_hashref has value key');

my $upd = $dbh->do(
    'UPDATE dbd_d1_test SET value = ? WHERE label = ?',
    undef, 9.9, 'alpha',
);
ok($upd >= 1, 'UPDATE affected >= 1 row');

eval { $dbh->do('DROP TABLE IF EXISTS dbd_d1_test') };
is($@, '', 'DROP TABLE did not die');

$dbh->disconnect;
