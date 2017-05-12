#!/usr/bin/perl
use warnings;
use strict;
use lib qw(lib t);
use Benchmark;

use Ambrosia::DataProvider;
use Ambrosia::QL;

use Data::Dumper;

my $confDS = {
    DBI => [
        {
            engine_name   => 'mysql',
            source_name   => 'Client',
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

my $d = storage()->driver('DBI', 'Client');
my $dbh = $d->handler();

$dbh->do(q~DROP TABLE IF EXISTS `tClient`~);
$dbh->do(<<CREATE_TABLE);
 CREATE TABLE `tClient` (
  `ClientId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `LastName` varchar(32) NOT NULL,
  `FirstName` varchar(32) NOT NULL,
  `MiddleName` varchar(32) NOT NULL,
  `Age` tinyint(4) NOT NULL,
  PRIMARY KEY (`ClientId`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8
CREATE_TABLE
$d->save_transaction();

my $NUM_ITER = 100;
my $NUM_ROWS = 5000;

for ( 1 .. $NUM_ROWS )
{
    $d->source('tClient')
        ->insert()
        ->what(qw/LastName FirstName MiddleName Age/)
        ->execute('LastName'.$_, 'FirstName'.$_, 'MiddleName'.$_, 20+$_);
}
$d->save_transaction();

my $e;
my $cnt=0;

timethese($NUM_ITER, {
    'selectWithoutLimit' => sub {
        my @r = Ambrosia::QL
            ->from('tClient', \$e)
            ->in(storage()->driver('DBI', 'Client'))
            ->select()
            ->what(qw/LastName FirstName MiddleName Age/)
            ->predicate(sub{
                $cnt++;
                $e->{tClient_Age} == 32})
            ->take(3);
    },
    'selectWithLimit' => sub {
        my @r = Ambrosia::QL
            ->from('tClient', \$e)
            ->in(storage()->driver('DBI', 'Client'))
            ->select()
            ->what(qw/LastName FirstName MiddleName Age/)
            ->predicate('Age', '=', 32)
            ->take(3);
    },
    'selectWithIndexSerch' => sub {
        my @r = Ambrosia::QL
            ->from('tClient', \$e)
            ->in(storage()->driver('DBI', 'Client'))
            ->select()
            ->what(qw/LastName FirstName MiddleName Age/)
            ->predicate('ClientId', '<', 20)
            ->take(3);
    },
});

$dbh->do(q~DROP TABLE IF EXISTS `tClient`~);
$d->save_transaction();
print "\n$cnt\n";