#!perl

use strict;
use warnings;

use Test::More;

use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Query;
use DBIx::Class::QueryLog::Transaction;


my $ql = DBIx::Class::QueryLog->new;
ok($ql->isa('DBIx::Class::QueryLog'), 'new');
ok($ql->isa('DBIx::Class::Storage::Statistics'), "extends base debug object");

$ql->query_start('SELECT * from foo');
$ql->query_end('SELECT * from foo');
ok(scalar(@{ $ql->log }) == 1, 'log count w/1 query');

$ql->txn_begin;
$ql->query_start('SELECT * from foo');
$ql->query_end('SELECT * from foo');
$ql->txn_commit;

ok(scalar(@{ $ql->log }) == 2, 'log count w/1 query + 1 trans');
my $log = $ql->log;
ok(scalar(@{ $log->[1]->queries }) == 1, '1 query in txn');
ok($log->[1]->committed, 'Committed txn');
ok(!$log->[1]->rolledback, '! Rolled back txn');

my $output = "";
{
  package Printable;

  sub print {
    my ($self, @args) = @_;
    $output .= join('', @args);
  }
}

$ql->passthrough(1);
$ql->debugfh(bless {}, "Printable");
$ql->txn_begin;
$ql->query_start('SELECT * from foo');
$ql->query_end('SELECT * from foo');
$ql->query_start('SELECT * from foo');
$ql->query_end('SELECT * from foo');
$ql->txn_rollback;

ok(scalar(@{ $ql->log }) == 3, 'log count w/1 query + 2 trans');
$log = $ql->log;
ok(scalar(@{ $log->[2]->queries }) == 2, '2 queries in 2nd txn');
ok($log->[2]->rolledback, 'Rolled back 2nd txn');
ok(!$log->[2]->committed, 'Not committed 2nd txn');

is( $output, <<'EOF', "Passthrough worked");
BEGIN WORK
SELECT * from foo: 
SELECT * from foo: 
ROLLBACK
EOF

done_testing;
