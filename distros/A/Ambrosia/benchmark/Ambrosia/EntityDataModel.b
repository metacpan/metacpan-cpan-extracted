#!/usr/bin/perl
use warnings;
use strict;
use lib qw(lib t);
use Benchmark;

use Ambrosia::DataProvider;
use Ambrosia::EntityDataModel;
use PersonEDM;


my $confDS = {
    DBI => [
        {
            engine_name   => 'mysql',
            source_name   => 'Employee',
            catalog       => undef,#optional
            schema        => 'test',
            host          => 'localhost',#optional
            port          => 3306,#optional
            user          => 'root',
            password      => '',
#            engine_params => 'database=test;host=localhost;',
            additional_params => { AutoCommit => 0, RaiseError => 1, LongTruncOk => 1 },
            additional_action => sub { my $dbh = shift; $dbh->do('SET NAMES utf8')},
        },
    ]
};

instance Ambrosia::DataProvider(test => $confDS);
Ambrosia::DataProvider::assign 'test';

my $d = storage()->driver('DBI', 'Employee');
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

$d->save_transaction();

my $NUM_ITER = 1000;
my $i = 1;
timethese($NUM_ITER, {
    'save' => sub {
            my $p = new PersonEDM(FirstName => 'John'.$i, LastName => 'Smit'.$i, Age => 20+$i);
            $p->save();
            $d->save_transaction();
            $i++;
        },
});

$i = 1;
timethese($NUM_ITER, {
    'load' => sub {
            PersonEDM->load($i++)->as_hash;
            #$d->save_transaction();
        },
});


#$d->save_transaction()->close_connection();
#PersonEDM->load($p->PersonId)->as_hash();

$dbh->do(q~DROP TABLE IF EXISTS `tPerson`~);
$d->save_transaction()->close_connection();
