#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Database;
use AnyEvent;
use Time::HiRes qw( time );

use AnyEvent::DBI::MySQL;


my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';

my $dbh1 = AnyEvent::DBI::MySQL->connect($h->connection_info);
my $dbh2 = AnyEvent::DBI::MySQL->connect($h->connection_info);
my ($t, $res1, $res2);

$t = time;
$res1 = $dbh1->selectcol_arrayref('SELECT 10, SLEEP(1)');
$res2 = $dbh2->selectcol_arrayref('SELECT 20, SLEEP(1)');
ok(time - $t > 1.5, 'sync');
is_deeply($res1, [10], 'res1');
is_deeply($res2, [20], 'res2');

my $cv1 = AnyEvent->condvar;
my $cv2 = AnyEvent->condvar;
$t = time;
$dbh1->selectcol_arrayref('SELECT 10, SLEEP(1)', sub { $cv1->send(shift) });
$dbh2->selectcol_arrayref('SELECT 20, SLEEP(1)', sub { $cv2->send(shift) });
$res1 = $cv1->recv;
$res2 = $cv2->recv;
ok(time - $t < 1.5, 'async');
is_deeply($res1, [10], 'res1');
is_deeply($res2, [20], 'res2');

done_testing();

