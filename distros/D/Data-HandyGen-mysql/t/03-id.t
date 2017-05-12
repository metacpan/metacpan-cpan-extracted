#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;

plan skip_all => 'mysql_install_db not found.'
    unless `which mysql_install_db 2>/dev/null`;

main();
done_testing();

exit(0);


#
# Tests of ID column (primary key)
#
# This script tests the following cases.
#
# (1)Explicitly specifies a value of primary key. The values will be assigned properly.
#
# (2)A primary key consisted of single integer column with auto_increment attribute. The value will be assigned by auto_increment.
#
# (3)A primary key consisted of single integer column without auto_increment attribute. The value will be max value of existing primary key plus 1. Only at the first insert to the table, an SQL statement will be issued to retrieve max value of primary keys. The max value will be preserved, and it is incremented and used since then.
#
# (4)A primary key consisted of single string column. (This functionarity is not implemented yet, so I will write a test later.)
#
# (5)A primary key consisted of multiple columns (any types). (This functionarity is not implemented yet, so I will write a test later.)
#

sub main {

    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;

    test_0($dbh); 
    test_1($dbh);
     

    $dbh->disconnect;
}


# Test case (1) and (2) are tested here.
sub test_0 {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_0 (
            id      integer primary key auto_increment,
            str     varchar(10)
        )
    });
    $dbh->do(q{ALTER TABLE table_test_0 AUTO_INCREMENT = 100});  #  next ID = 100

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    #  specifies key value
    $hd->_set_user_valspec('table_test_0', { id => 99 });
    my ($exp_id, $real_id) = $hd->get_id('table_test_0');
    is($exp_id, 99);
    is($real_id, 99);

    #  auto_increment is incremented from 99 to 100
    my $id = $hd->insert('table_test_0');

    #  clear valspec 
    $hd->_set_user_valspec('table_test_0', {});

    #  retrieves next auto_increment value (maybe 100)
    ($exp_id, $real_id) = $hd->get_id('table_test_0');
    is($exp_id, 100);
    is($real_id, undef);
}


#  Test case (3) is tested here.
sub test_1 {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_1 (
            id      integer primary key,
            str     varchar(10)
        )
    });

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);
    my $id = $hd->get_id('table_test_1');
    ok($id =~ /^\d+$/, "no auto_increment column. result id = $id");
}



