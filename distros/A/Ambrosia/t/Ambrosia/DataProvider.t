#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;
use Test::Exception;
use lib qw(lib t .);
use Carp;

use Data::Dumper;

BEGIN {
    use_ok( 'Ambrosia::DataProvider' ); #test #1
}

my $confDS = do 'db.params';

instance Ambrosia::DataProvider(test => $confDS);
Ambrosia::DataProvider::assign 'test';

my $s1 = storage();
my $s2 = storage();
ok($s1->equal($s2,0,1) eq '1', 'self is identical self');

my $d = storage()->driver('DBI', 'Client');
ok ($d, 'get driver');

my $dbh = $d->handler();
ok ($dbh, 'get handler');

ok ($d->begin_transaction(), 'begin_transaction');

$dbh->do(q~DROP TABLE IF EXISTS `tClient`~);
$dbh->do(<<CREATE_TABLE);
 CREATE TABLE `tClient` (
  `ClientId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `LastName` varchar(32) NOT NULL,
  `FirstName` varchar(32) NOT NULL,
  `MiddleName` varchar(32) NOT NULL,
  `Age` tinyint(4) NOT NULL,
  PRIMARY KEY (`ClientId`)
) ENGINE=InnoDB AUTO_INCREMENT=5001 DEFAULT CHARSET=utf8
CREATE_TABLE

ok ($d->save_transaction(), 'save_transaction');

my $NUM_ROWS = 20;
for ( 1 .. $NUM_ROWS )
{
    $d->source('tClient')
        ->insert()
        ->what(qw/LastName FirstName MiddleName Age/)
        ->execute('LastName'.$_, 'FirstName'.$_, 'MiddleName'.$_, 20+$_);
}
$d->save_transaction();

ok($d->source('tClient')->count() == $NUM_ROWS, "insert $NUM_ROWS rows into table");

for ( 1 .. $NUM_ROWS )
{
    $d->source('tClient')
        ->insert()
        ->what(qw/LastName FirstName MiddleName Age/)
        ->execute('LastName'.$_, 'FirstName'.$_, 'MiddleName'.$_, 20+$_);
}
ok ($d->cancel_transaction(), 'cancel_transaction');

ok($d->source('tClient')->count() == $NUM_ROWS, "rollback inserted $NUM_ROWS rows into table");

{
    my $q = $d->reset()->source('tClient')
                ->what(qw/LastName FirstName MiddleName Age/)
                ->predicate('Age', '>', 20)
                ->predicate('Age', '<=', 30)
                ->order_by('Age');

    my @res = ();
    my $cnt = 0;
    while( my $r = $q->next() )
    {
        push @res, $r;
        last if $cnt++ > 100;
    }

    ok($cnt == 10, 'get 10 rows');
    ok($res[4]->{tClient_LastName} eq 'LastName5', 'check getting row');
}
{
    my $q = $d->reset()->source('tClient')
                ->what(qw/LastName FirstName MiddleName Age/)
                ->predicate(['Age', '<=', 30],['Age', '>', 35])
                ->order_by('Age');

    my @res = ();
    my $cnt = 0;
    while( my $r = $q->next() )
    {
        push @res, $r;
        last if $cnt++ > 100;
    }

    ok($cnt == 15, 'get 15 rows');
    ok($res[11]->{tClient_LastName} eq 'LastName17', 'check getting row');
}

$d->handler->do(q~DROP TABLE IF EXISTS `tClient`~);
ok ($d->close_connection(), 'close_connection');





