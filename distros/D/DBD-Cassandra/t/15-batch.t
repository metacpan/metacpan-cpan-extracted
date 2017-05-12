use 5.010;
use warnings;
use strict;
use DBI;
use Test::More;

unless ($ENV{CASSANDRA_HOST}) {
    plan skip_all => "CASSANDRA_HOST not set";
}

plan tests => 2;

my $tls= $ENV{CASSANDRA_TLS} // '';
my $dbh= DBI->connect("dbi:Cassandra:host=$ENV{CASSANDRA_HOST};keyspace=dbd_cassandra_tests;read_timeout=5;connect_timeout=5;write_timeout=5;tls=$tls", $ENV{CASSANDRA_USER}, $ENV{CASSANDRA_AUTH}, {RaiseError => 1});
ok($dbh);

$dbh->do('drop table if exists test_batch');
ok($dbh->do("create table test_batch (
    pk int,
    value int,
    primary key ( pk )
)"));

SCOPED: {
    local $SIG{__WARN__}= sub { ok(0); print STDERR @_; };

    my $sth= $dbh->prepare("BEGIN BATCH
        INSERT INTO test_batch (pk, value)
        VALUES (?, ?)
        IF NOT EXISTS
        UPDATE test_batch
        SET value = 5
        WHERE pk = ?
        APPLY BATCH;",
    );
    $sth->execute(1, 2, 1);
}

$dbh->disconnect;
