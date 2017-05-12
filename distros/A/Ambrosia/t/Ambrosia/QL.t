#!/usr/bin/perl
use strict;
use warnings;
use lib qw(lib t ..);

use Test::More tests => 7;
use Test::Deep;

use Data::Dumper;

use Ambrosia::DataProvider;
#use Ambrosia::QL;

BEGIN {
    use_ok( 'Ambrosia::QL' ); #test #1
}

my $confDS = do 'db.params';

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

my $NUM_ROWS = 30;
for ( 1 .. $NUM_ROWS )
{
    $d->source('tClient')
        ->insert()
        ->what(qw/LastName FirstName MiddleName Age/)
        ->execute('LastName'.$_, 'FirstName'.$_, 'MiddleName'.$_, 20+$_);
}
for ( 1 .. $NUM_ROWS )
{
    $d->source('tClient')
        ->insert()
        ->what(qw/LastName FirstName MiddleName Age/)
        ->execute('LastName'.$_, 'FirstName'.$_, 'MiddleName'.$_, 20+$_);
}
$d->save_transaction();

################################################################################
{## test #2 ##
    my @r = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate('ClientId', '=', 22)
        ->take(1);

    cmp_deeply(\@r,
        [{
          tClient_LastName   => 'LastName22',
          tClient_FirstName  => 'FirstName22',
          tClient_MiddleName => 'MiddleName22',
          tClient_Age        => 42,
          }],
        'load one record with SQL predicate'
        );
}

{## test #3 ##
    my @r = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate(sub{
            shift()->{tClient_Age} == 42})
        ->take();

    cmp_deeply(\@r,
        [
            {
             tClient_LastName   => 'LastName22',
             tClient_FirstName  => 'FirstName22',
             tClient_MiddleName => 'MiddleName22',
             tClient_Age        => 42,
            },
            {
             tClient_LastName   => 'LastName22',
             tClient_FirstName  => 'FirstName22',
             tClient_MiddleName => 'MiddleName22',
             tClient_Age        => 42,
            }
        ],
        'load two record with subrutine predicate'
        );
}

{## test #4 ##
    my $client;
    my @r = Ambrosia::QL
        ->from('tClient', \$client)
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate(sub{
            shift->{tClient_Age} == 42})
        ->select(sub {
            return {map { my $k = $_; $k =~ s/^tClient_//; $k => $client->{$_}; } keys %$client};
        })
        ->take(1);

    #print Dumper(\@r);

    cmp_deeply(\@r,
        [
            {
             LastName   => 'LastName22',
             FirstName  => 'FirstName22',
             MiddleName => 'MiddleName22',
             Age        => 42,
            },
        ],
        'load one record with subrutine predicate and transformation in select'
        );
}

{## test #5 ##
    my @r = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->uniq(qw/LastName FirstName MiddleName Age/)
        ->predicate('ClientId', '=', 22)
        ->select()
        ->take();

    cmp_deeply(\@r,
        [{
          tClient_LastName   => 'LastName22',
          tClient_FirstName  => 'FirstName22',
          tClient_MiddleName => 'MiddleName22',
          tClient_Age        => 42,
          }],
        'load one unique record'
        );
}

{## test #6 ##
    my $ql = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->what(qw/LastName FirstName MiddleName Age/)
        ->predicate('Age', '=', 42);

    my @r = ();
    while(my $r = $ql->next() )
    {
        push @r, $r;
    }
    $ql->destroy();

    #print Dumper(\@r);

    cmp_deeply(\@r,
        [
            {
             tClient_LastName   => 'LastName22',
             tClient_FirstName  => 'FirstName22',
             tClient_MiddleName => 'MiddleName22',
             tClient_Age        => 42,
            },
            {
             tClient_LastName   => 'LastName22',
             tClient_FirstName  => 'FirstName22',
             tClient_MiddleName => 'MiddleName22',
             tClient_Age        => 42,
            }
        ],
        'load two record with "next"'
        );
}

{## test #7 ##
    my @r = Ambrosia::QL
        ->from('tClient')
        ->in(storage()->driver('DBI', 'Client'))
        ->uniq(qw/LastName FirstName MiddleName Age/)
        ->predicate(['ClientId', '=', 22],['ClientId', '=', 13])
        ->select()
        ->take();

    cmp_deeply(\@r,
        bag(
         {
          tClient_LastName   => 'LastName22',
          tClient_FirstName  => 'FirstName22',
          tClient_MiddleName => 'MiddleName22',
          tClient_Age        => 42,
         },
         {
          tClient_LastName   => 'LastName13',
          tClient_FirstName  => 'FirstName13',
          tClient_MiddleName => 'MiddleName13',
          tClient_Age        => 33,
          }
        ),
        'load two unique records'
        );
}

#$dbh->do(q~DROP TABLE IF EXISTS `tClient`~);
storage->foreach('save_transaction');
storage->foreach('close_connection');
