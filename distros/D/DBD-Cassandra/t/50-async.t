use 5.010;
use warnings;
use strict;
use DBI;
use Test::More;

unless ($ENV{CASSANDRA_HOST}) {
    plan skip_all => "CASSANDRA_HOST not set";
}

plan tests => 3;

my $tls= $ENV{CASSANDRA_TLS} // '';
my $port= $ENV{CASSANDRA_PORT} ? ";port=$ENV{CASSANDRA_PORT}" : "";
my $dbh= DBI->connect("dbi:Cassandra:host=$ENV{CASSANDRA_HOST};keyspace=dbd_cassandra_tests;read_timeout=5;connect_timeout=5;write_timeout=5;tls=$tls$port", $ENV{CASSANDRA_USER}, $ENV{CASSANDRA_AUTH}, {RaiseError => 1});
ok($dbh);

$dbh->do('create table if not exists test_async (id bigint primary key)');
$dbh->do('truncate test_async');

my $count= 100000;
my (@pending, @reusable);
for my $i (1..$count) {
    my $sth= (shift @reusable) || $dbh->prepare("insert into test_async (id) values (?)", {async => 1});
    $sth->execute($i);
    push @pending, $sth;

    if (@pending > 5000) {
        my $pending_sth= shift @pending;
        $pending_sth->x_finish_async;
        push @reusable, $pending_sth;
    }
}

my $ok= 1;
$ok &&= $_->x_finish_async for reverse @pending;
ok($ok);

my $rows= $dbh->selectall_arrayref('select * from test_async');
ok(0+@$rows == $count) or diag("Expected $count rows, got ".(0+@$rows));

$dbh->disconnect;
