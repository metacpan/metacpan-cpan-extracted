#!perl

use strict;
use warnings;

use Test::More;

use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Analyzer;
use DBIx::Class::QueryLog::Query;
use DBIx::Class::QueryLog::Transaction;

my $ql = DBIx::Class::QueryLog->new;
$ql->query_start('SELECT * from foo');
$ql->query_end('SELECT * from foo');
cmp_ok($ql->log->[0]->bucket, 'eq', 'default', 'default bucket');

$ql->bucket('foo');
$ql->txn_begin;
$ql->query_start('SELECT * from foo');
$ql->query_end('SELECT * from foo');
is($ql->current_transaction->count, 1, 'count of ::Transaction works');

$ql->txn_commit;
cmp_ok($ql->log->[1]->bucket, 'eq', 'foo', 'foo bucket');

cmp_ok($ql->log->[1]->queries->[0]->bucket, 'eq', 'foo', 'inner query bucket');

cmp_ok($ql->log->[0]->bucket, 'eq', 'default', 'first still default bucket');

my $ana = DBIx::Class::QueryLog::Analyzer->new({
    querylog => $ql
});
my $total = $ana->get_totaled_queries_by_bucket;
cmp_ok(scalar(keys(%{ $total })), '==', 2, '2 buckets');

done_testing;
