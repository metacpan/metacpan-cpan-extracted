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


#  get_id

sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;
    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    
    test_with_valspec($hd);
    test_without_valspec_auto_increment($hd);
    test_without_valspec_no_auto_increment($hd);
    

    $dbh->disconnect();
}


sub test_with_valspec {
    my ($hd) = @_;

    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_vs (
            id integer primary key auto_increment
        )
    });

    $hd->_set_user_valspec('test_vs', { id => 135 });
    my ($exp_id, $real_id) = $hd->get_id('test_vs');
    is($exp_id, 135);
    is($real_id, 135);
}


sub test_without_valspec_auto_increment {
    my ($hd) = @_;

    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_nvs_ai (
            id integer primary key auto_increment
        )
    });

    my ($exp_id, $real_id) = $hd->get_id('test_nvs_ai');
    is($exp_id, 1);
    is($real_id, undef);

    $dbh->do(q{
        ALTER TABLE test_nvs_ai AUTO_INCREMENT = 223
    });
    ($exp_id, $real_id) = $hd->get_id('test_nvs_ai');
    is($exp_id, 223);
    is($real_id, undef);
}


sub test_without_valspec_no_auto_increment {
    my ($hd) = @_;

    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_nvs_nai (
            id integer primary key
        )
    });

    my ($exp_id, $real_id) = $hd->get_id('test_nvs_nai');
    ok(defined($exp_id));
    ok(defined($real_id));
    is($exp_id, $real_id);
}


