#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Cassandra::Client;
use Time::HiRes qw/time/;
use Promises qw/collect/, backend => ['AnyEvent'];
use AnyEvent;

plan skip_all => "CASSANDRA_HOST not set" unless $ENV{CASSANDRA_HOST};

my $client= Cassandra::Client->new(
    contact_points => [split /,/, $ENV{CASSANDRA_HOST}],
    username  => $ENV{CASSANDRA_USER},
    password  => $ENV{CASSANDRA_AUTH},
    anyevent  => 1,
    throttler => "Adaptive",
    tls       => $ENV{CASSANDRA_TLS},
);
$client->connect();

my $db= 'perl_cassandra_client_tests';
$client->execute("drop keyspace if exists $db");
$client->execute("create keyspace $db with replication={'class':'SimpleStrategy', 'replication_factor': 1}");
$client->execute("create table $db.test_int (id int primary key, value int)");

my $insert_query= "insert into $db.test_int (id, value) values (?, ?)";
my $select_query= "select id, value from $db.test_int where id=?";

my $rounds= $ENV{BENCH_ROUNDS} || 1;
my $multiply= $ENV{BENCH_MULTIPLY} || 1;
for (1..$rounds) {
    SYNC_INS: {
        next if $ENV{BENCH_SKIP_SYNC};
        my $num= 1000 * $multiply;
        my $t0= -time();
        for (1..$num) {
            $client->execute($insert_query, [ $_, $_ * 2 ]);
        }
        my $diff= time() + $t0;
        ok(1, sprintf "$num synchronous inserts: %.1f seconds", $diff);
    }
    SYNC_SEL: {
        next if $ENV{BENCH_SKIP_SYNC};
        my $num= 1000 * $multiply;
        my $t0= -time();
        for (1..$num) {
            $client->execute($select_query, [ $_ ]);
        }
        my $diff= time() + $t0;
        ok(1, sprintf "$num synchronous selects: %.1f seconds", $diff);
    }
    PROMISES_INS: {
        my $num= 1000 * $multiply;
        my $t0= -time();
        my @promises;
        for (1..$num) {
            push @promises, $client->async_execute($insert_query, [ $_, $_ * 2 ]);
        }
        my $cv= AE::cv;
        my $fail;
        collect(@promises)->then(sub { $cv->send; }, sub { $fail= 1; $cv->send; });
        $cv->recv;
        my $diff= time() + $t0;
        ok(1, sprintf "$num asynchronous inserts: %.1f seconds", $diff);
    }
    PROMISES_SEL: {
        my $num= 1000 * $multiply;
        my $t0= -time();
        my @promises;
        for (1..$num) {
            push @promises, $client->async_execute($select_query, [ $_ ]);
        }
        my $cv= AE::cv;
        my $fail;
        collect(@promises)->then(sub { $cv->send; }, sub { $fail= 1; $cv->send; });
        $cv->recv;
        my $diff= time() + $t0;
        ok(1, sprintf "$num asynchronous selects: %.1f seconds", $diff);
    }
    FUTURES_INS: {
        my $num= 1000 * $multiply;
        my $t0= -time();
        my @futures;
        for (1..$num) {
            push @futures, $client->future_execute($insert_query, [ $_, $_ * 2 ]);
        }
        $_->() for @futures;
        my $diff= time() + $t0;
        ok(1, sprintf "$num synchronous inserts via futures: %.1f seconds", $diff);
    }
    FUTURES_SEL: {
        my $num= 1000 * $multiply;
        my $t0= -time();
        my @futures;
        for (1..$num) {
            push @futures, $client->future_execute($select_query, [ $_ ]);
        }
        $_->() for @futures;
        my $diff= time() + $t0;
        ok(1, sprintf "$num synchronous selects via futures: %.1f seconds", $diff);
    }
}

done_testing;
