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


#   _val_smallint 
#  

sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;
    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);


    #  Write test code here.
    test_signed($hd);
    test_unsigned($hd);

    $dbh->disconnect();
}


#  test_signed 
#    Any values are between 0 and 127
sub test_signed {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_signed (
            value smallint not null
        )
    });

    my $col_def = $hd->_table_def('test_signed')->column_def('value');

    my ($max, $min);
    for (1..1000) {
        my $ret = $hd->_val_smallint($col_def);
        defined($max) or $max = $ret;
        defined($min) or $min = $ret;
        $max < $ret and $max = $ret;
        $ret < $min and $min = $ret;
    }
    ok($min >= 0, "result of min = $min");
    ok($max <= 32767, "result of max = $max");
}


#  test_unsigned
#    Amy values are between 0 and 255
sub test_unsigned {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_unsigned (
            value smallint unsigned not null
        )
    });

    my $col_def = $hd->_table_def('test_unsigned')->column_def('value');

    my ($max, $min);
    for (1..1000) {
        my $ret = $hd->_val_smallint($col_def);
        defined($max) or $max = $ret;
        defined($min) or $min = $ret;
        $max < $ret and $max = $ret;
        $ret < $min and $min = $ret;
    }
    ok($min >= 0, "result of min = $min");
    ok($max <= 65535, "result of max = $max");
}

    


