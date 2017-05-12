#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;

plan skip_all => 'mysql_install_db not found'
    unless `which mysql_install_db 2>/dev/null`;

main();
done_testing();

exit(0);


#
#  Test for get_cols_requiring_value.
#
sub main {

    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;

    test_0($dbh); 
    test_1($dbh);
    test_2($dbh);

    $dbh->disconnect;
}


#
#  A column with auto_increment attribute is considered that it does not require value, unless its value is explicitly specified by user.
#
sub test_0 {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_0 (
            id      integer primary key auto_increment
        )
    });

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    my $cols = $hd->get_cols_requiring_value('table_test_0');
    is_deeply($cols, []);

    $hd->_set_user_valspec('table_test_0', { id => 100 });
    $cols = $hd->get_cols_requiring_value('table_test_0');
    is_deeply($cols, ['id']);
}


#
#  A column which has DEFAULT is considered that it does not require value, unless its value is explicitly specified by user.
#
sub test_1 {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_1 (
            id      integer not null default 100 
        )
    });

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    my $cols = $hd->get_cols_requiring_value('table_test_1');
    is_deeply($cols, []);

    $hd->_set_user_valspec('table_test_1', { id => 200 });
    $cols = $hd->get_cols_requiring_value('table_test_1');
    is_deeply($cols, ['id']);
}



#  
#  A 'NULLABLE' column is considered that it does not require value, unless user specifies its value explicitly.
#
sub test_2 {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_2 (
            id      integer 
        )
    });

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    my $cols = $hd->get_cols_requiring_value('table_test_2');
    is_deeply($cols, []);

    $hd->_set_user_valspec('table_test_2', { id => 30 });
    $cols = $hd->get_cols_requiring_value('table_test_2');
    is_deeply($cols, ['id']);
}




