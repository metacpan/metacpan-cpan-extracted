#!perl
use 5.010;
use strict;
use warnings;
use File::Basename qw//; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use TestCassandra;
use Cassandra::Client::Policy::Throttle::Adaptive;
use Time::HiRes qw/time/;
use AnyEvent::XSPromises qw/collect/;
use AnyEvent;

my $nr_rows = $ENV{PARALLEL_TEST_RECORDS} || 10;
plan skip_all => "Missing Cassandra test environment" unless TestCassandra->is_ok;
plan tests => $nr_rows;

my $client= TestCassandra->new(
    anyevent  => 1,
);
$client->connect();

my $db= 'perl_cassandra_client_tests';
$client->execute("drop keyspace if exists $db");
$client->execute("create keyspace $db with replication={'class':'SimpleStrategy', 'replication_factor': 1}");
$client->execute("create table $db.test_int (id int primary key, value int)");

for (1..$nr_rows) {
    $client->execute("insert into $db.test_int (id, value) values (?, ?)", [$_, $_]);
}

my $insert_query= "insert into $db.test_int (id, value) values (?, ?)";
my $select_query= "select id, value from $db.test_int where id=?";

my @promises;
for (1..$nr_rows) {
    my $requested_id = $_;
    push @promises, $client->async_execute($select_query, [ $requested_id ])
        ->then(sub {
            my $rs = shift;
            my $rs_id = @{$rs->row_hashes()}[0]->{"id"};
            ok($rs_id == $requested_id, "response matches request for id <$requested_id>");
            return undef;
        });
}

my $cv= AE::cv;
my $fail;
collect(@promises)->then(sub { $cv->send; }, sub { $fail= 1; $cv->send; });
$cv->recv;

1;
