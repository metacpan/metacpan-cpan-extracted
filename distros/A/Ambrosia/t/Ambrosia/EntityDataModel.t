#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use Test::Deep;
use lib qw(lib t ..);
use Carp;

use Data::Dumper;

use Ambrosia::DataProvider;
use t::PersonEDM;

BEGIN {
    use_ok( 'Ambrosia::EntityDataModel' ); #test #1
}

my $confDS = do 'db.params';

instance Ambrosia::DataProvider(test => $confDS);
Ambrosia::DataProvider::assign 'test';

my $d = storage()->driver('DBI', 'Client');
my $dbh = $d->handler();

$dbh->do(q~DROP TABLE IF EXISTS `tPerson`~);
$dbh->do(<<CREATE_TABLE);
 CREATE TABLE `tPerson` (
  `PersonId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `LastName` varchar(32) NOT NULL,
  `FirstName` varchar(32) NOT NULL,
  `Age` tinyint(4) NOT NULL,
  PRIMARY KEY (`PersonId`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8
CREATE_TABLE

ok ($d->save_transaction(), 'save_transaction');

my $p = t::PersonEDM->new(FirstName => 'John', LastName => 'Smit', Age => 33);
ok($p, 'created');
ok($p->save(), 'saved');
ok($p->PersonId == 1, 'get id');

cmp_deeply($p->as_hash(), t::PersonEDM->load($p->PersonId)->as_hash(), 'load from cache');

$d->save_transaction()->close_connection();
cmp_deeply($p->as_hash(), t::PersonEDM->load($p->PersonId)->as_hash(), 'load');

ok ($d->close_connection(), 'close_connection');
