#!perl

use strict;
use warnings;

use Test::More;

use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Analyzer;
use DBIx::Class::QueryLog::Query;
use DBIx::Class::QueryLog::Transaction;

my $time = 0;

my $ql = DBIx::Class::QueryLog->new(
    __time => sub { $time },
);
$ql->query_start('SELECT * from foo', 'fast');
$ql->query_end('SELECT * from foo', 'fast');

$ql->query_start('SELECT * from foo2', 'fast');
$ql->query_end('SELECT * from foo2', 'fast');

$ql->query_start('SELECT * from foo', 'slow');
$time += 3;
$ql->query_end('SELECT * from foo', 'slow');

$ql->txn_begin;
$ql->query_start('SELECT * from foo', 'medium');
$time += 2;
$ql->query_end('SELECT * from foo', 'medium');
$ql->txn_commit;

my $ana = DBIx::Class::QueryLog::Analyzer->new({
    querylog => $ql
});
my $slow = $ana->get_slowest_query_executions('SELECT * from foo');
cmp_ok(scalar(@{ $slow }), '==', 3, '3 executions found');
cmp_ok($slow->[0]->params->[0], 'eq', 'slow', 'slow executions 0');
cmp_ok($slow->[1]->params->[0], 'eq', 'medium', 'slow executions 1');
cmp_ok($slow->[2]->params->[0], 'eq', 'fast', 'slow executions 2');

my $other = $ana->get_slowest_query_executions('SELECT * from foo2');
cmp_ok(scalar(@{ $other }), '==', 1, '1 executions found');

my $fast = $ana->get_fastest_query_executions('SELECT * from foo');
cmp_ok(scalar(@{ $fast }), '==', 3, '3 executions found');
cmp_ok($fast->[2]->params->[0], 'eq', 'slow', 'fast executions 2');
cmp_ok($fast->[1]->params->[0], 'eq', 'medium', 'fast executions 1');
cmp_ok($fast->[0]->params->[0], 'eq', 'fast', 'fast executions 0');

done_testing;
