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
my $dbh= DBI->connect("dbi:Cassandra:host=$ENV{CASSANDRA_HOST};keyspace=dbd_cassandra_tests;read_timeout=1;connect_timeout=1;write_timeout=1;tls=$tls", $ENV{CASSANDRA_USER}, $ENV{CASSANDRA_AUTH}, {RaiseError => 1});
ok($dbh);

$dbh->do('create table if not exists test_utf8 (id bigint primary key, str varchar)');

my $test_string= "";
utf8::decode($test_string);
for (1..100) {
    $test_string .= chr(int(rand(30000)+1000));
}

$dbh->do("insert into test_utf8 (id, str) values (?,?)", undef, 1, $test_string);
my $row= $dbh->selectrow_arrayref('select str from test_utf8 where id=1');
ok($row->[0] eq $test_string);

$dbh->disconnect;
