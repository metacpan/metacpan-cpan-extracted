#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;


main();
exit(0);


# 

sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;
    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    test($hd); 


    $dbh->disconnect();

    done_testing();
}


sub test {
    my ($hd) = @_;

    $hd->dbh->do('SET FOREIGN_KEY_CHECKS = 1');
    my $res = $hd->_check_fk_check_status();
    ok(($res eq 'ON' or $res == 1), "FOREIGN_KEY_CHECKS = $res");
    
    $hd->dbh->do('SET FOREIGN_KEY_CHECKS = 0');
    $res = $hd->_check_fk_check_status();
    ok(($res eq 'OFF' or $res == 0), "FOREIGN_KEY_CHECKS = $res");
}

