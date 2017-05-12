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


#  _get_current_distinct_values

sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;
    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);


    #  Write test code here.
    test_norecord($hd);
    test_unique($hd);
    test_nonunique($hd);
    test_limit($hd);

    $dbh->disconnect();

    done_testing();
}


sub test_norecord {
    my ($hd) = @_;

    $hd->dbh->do(q{
        CREATE TABLE table_norecord (
            col1 integer primary key
        )
    });

    my $res = $hd->_get_current_distinct_values('table_norecord', 'col1');
    is_deeply($res, {});
}

sub test_unique {
    my ($hd) = @_;

    $hd->dbh->do(q{
        CREATE TABLE table_unique (
            col2 integer primary key
        )
    });

    for ( 0, 1, 10, 100 ) {
        $hd->dbh->do(q{INSERT INTO table_unique (col2) VALUES (?)}, undef, $_);
    }

    my $res = $hd->_get_current_distinct_values('table_unique', 'col2');
    is_deeply($res, { 0 => 1, 1 => 1, 10 => 1, 100 => 1 });
}

sub test_nonunique {
    my ($hd) = @_;

    $hd->dbh->do(q{
        CREATE TABLE table_nonunique (
            col3 integer
        )
    });

    for ( 1, 10, 1, 0, 0, 10, 100 ) {
        $hd->dbh->do(q{INSERT INTO table_nonunique (col3) VALUES (?)}, undef, $_);
    }

    my $res = $hd->_get_current_distinct_values('table_nonunique', 'col3');
    is_deeply($res, { 0 => 1, 1 => 1, 10 => 1, 100 => 1 });
}


sub test_limit {
    my ($hd) = @_;

    $hd->dbh->do(q{
        CREATE TABLE table_limit (
            col4 integer
        )
    });

    #  Temporarily set 5 as a limit
    $Data::HandyGen::mysql::DISTINCT_VAL_FETCH_LIMIT = 5;

    for ( 0, 1, 2, 3, 2, 4, 5, 6 ) {
        $hd->dbh->do(q{INSERT INTO table_limit (col4) VALUES (?)}, undef, $_);
    }

    my $res = $hd->_get_current_distinct_values('table_limit', 'col4');
    is(keys %$res, 5);

    #  Reset to default
    $Data::HandyGen::mysql::DISTINCT_VAL_FETCH_LIMIT = 100;
}


