#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;

plan skip_all => 'mysql_install_db not found'
    unless `which mysql_install_db 2>/dev/null`;

main();
done_testing();

exit(0);


#  _value_exists_in_table_col

sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->do(q{
        CREATE TABLE test (
            id integer primary key,
            name varchar(10) not null
        )
    });
    $dbh->do(q{INSERT INTO test (id, name) VALUES (100, 'Apple')});
    $dbh->do(q{INSERT INTO test (id, name) VALUES (200, 'Banana')});
    $dbh->do(q{INSERT INTO test (id, name) VALUES (300, 'Banana')});
    $dbh->do(q{INSERT INTO test (id, name) VALUES (0, 'Banana')});
    
    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);
   
    is(1, $hd->_value_exists_in_table_col('test', 'id', 0));
    is(1, $hd->_value_exists_in_table_col('test', 'id', 100));
    is(0, $hd->_value_exists_in_table_col('test', 'id', 150));
    is(1, $hd->_value_exists_in_table_col('test', 'name', 'Apple'));
    is(3, $hd->_value_exists_in_table_col('test', 'name', 'Banana'));

    dies_ok { $hd->_value_exists_in_table_col() };
    dies_ok { $hd->_value_exists_in_table_col('test') };
    dies_ok { $hd->_value_exists_in_table_col('test', 'id') };

    $dbh->disconnect();
}



