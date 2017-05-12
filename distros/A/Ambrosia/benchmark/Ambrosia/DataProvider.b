#!/usr/bin/perl -w
use warnings;
use strict;
use lib qw(lib t);
use Benchmark;

use Ambrosia::DataProvider;

my $confDS = {
    DBI => [
        {
            engine_name   => 'mysql',
            source_name   => 'Employee',
            user          => 'root',
            password      => '',
            engine_params => 'database=test;host=localhost;',
            additional_params => { AutoCommit => 0, RaiseError => 1, LongTruncOk => 1 },
            additional_action => sub { my $dbh = shift; $dbh->do('SET NAMES utf8')},
        },
    ]
};

instance Ambrosia::DataProvider(test => $confDS);
Ambrosia::DataProvider::assign 'test';

my $d = storage()->driver('DBI', 'Employee');
my $dbh = $d->handler();

$dbh->do(q~DROP TABLE IF EXISTS `tClient`~);
$dbh->do(<<CREATE_TABLE);
 CREATE TABLE `tClient` (
  `Client_Id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `LastName` varchar(32) NOT NULL,
  `FirstName` varchar(32) NOT NULL,
  `MiddleName` varchar(32) NOT NULL,
  `Age` tinyint(4) NOT NULL,
  PRIMARY KEY (`Client_Id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8
CREATE_TABLE
$d->save_transaction();

my $NUM_ITER = 1000;

#    my $q = $d->reset()
#                ->source('tClient')
#                ->select()
#                ->what(qw/LastName FirstName MiddleName Age/)
#                ->predicate(['Client_Id', '<=', 30],['Client_Id', '>', $NUM_ITER-10])
#                ->next();
#exit;
my $count = 0;
sub insert
{
    my $i = shift;
    $d->reset()
        ->source('tClient')
        ->insert()
        ->what(qw/LastName FirstName MiddleName Age/)
        ->execute('LastName'.$i, 'FirstName'.$i, 'MiddleName'.$i, 20+$i);
    $d->save_transaction();
}

sub createSQL
{
    $d->reset()
        ->source('tClient')
        ->select()
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate(['Age', '<=', 30],['Age', '>', $NUM_ITER])
        ;#->order_by('Age');
}

sub select
{
    my $q = $d->reset()
                ->source('tClient')
                ->select()
                ->what(qw/LastName FirstName MiddleName Age/)
                ->predicate(['Age', '<=', 30],['Age', '>', $NUM_ITER])
                ;#->order_by('Age');

    while( my $r = $q->next() )
    {
        $count++;
    }
    $d->save_transaction();
}

sub selectIndex
{
    my $q = $d->reset()
                ->source('tClient')
                ->select()
                ->what(qw/LastName FirstName MiddleName Age/)
                ->predicate(['Client_Id', '<=', 30],['Client_Id', '>', $NUM_ITER-10])
                ;#->order_by('Age');

    while( my $r = $q->next() )
    {
        $count++;
    }
    $d->save_transaction();
}

sub selectIndex2
{
    my $q = $d->reset()
                ->source('tClient')
                ->select()
                ->what(qw/LastName FirstName MiddleName Age/)
                ->predicate('Client_Id', '=', 30)
                ;#->order_by('Age');

    while( my $r = $q->next() )
    {
        $count++;
    }
    $d->save_transaction();
}

sub dbi
{
    my $r = $d->handler->selectall_arrayref(q~
SELECT
    `tClient`.`LastName` AS tClient_LastName,
    `tClient`.`FirstName` AS tClient_FirstName,
    `tClient`.`MiddleName` AS tClient_MiddleName,
    `tClient`.`Age` AS tClient_Age
FROM `tClient`
WHERE (`tClient`.`Client_Id` <= '30' OR `tClient`.`Client_Id` > '990')
~, { Slice => {} });
    $d->save_transaction();
}

my $i = 1;
timethese($NUM_ITER, {
    'insert' => sub { insert($i++) },
});

timethese($NUM_ITER*10, {
    'createSQL' => \&createSQL,
});
print "\n";

timethese($NUM_ITER, {
    'select' => \&select,
});
print "rows count=$count\n\n"; $count=0;

timethese($NUM_ITER, {
    'selectIndex' => \&selectIndex,
    'dbi' => \&dbi,
});
print "rows count=$count\n\n"; $count=0;

timethese($NUM_ITER, {
    'selectIndex2' => \&selectIndex2,
});
print "rows count=$count\n"; $count=0;

$dbh->do(q~DROP TABLE IF EXISTS `tClient`~);
