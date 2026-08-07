#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp ();

BEGIN {
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
}
use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;
use BackendParity;

my $dir = File::Temp->newdir;
my $ad  = DBIx::Loop::Loop::IOAsync->new;
my $db  = DBIx::Loop->connect(
    "dbi:SQLite:dbname=$dir/parity.db", '', '',
    { RaiseError => 1, PrintError => 0, sqlite_unicode => 1 },
    loop => $ad, workers => 2,
);
is($db->capability, 'pool', 'runs on the pool backend');
BackendParity::run($db, $ad, name => 'pool/SQLite');

# disconnect with a query in flight fails it cleanly (no eternal pending)
{
    my $slow = $db->query(
        "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c WHERE x < 500000) SELECT COUNT(*) FROM c");
    $db->disconnect;
    ok($slow->is_ready, 'in-flight future settles on disconnect');
    ok($slow->is_failed, '... as a failure');
    like($slow->failure, qr/disconnect/i, '... naming the disconnect');
}

done_testing();
