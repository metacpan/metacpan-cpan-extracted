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


#   delete_all

sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;
    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    test_with_pk($hd);

    $dbh->disconnect();

    done_testing();
}


sub test_with_pk {
    my ($hd) = @_;

    my $dbh = $hd->dbh;
    $dbh->do(q{CREATE TABLE test1 ( id integer primary key )});
    $dbh->do(q{INSERT INTO test1 (id) VALUES (1), (2), (3)});
    
    $dbh->do(q{CREATE TABLE test2 ( id integer primary key )});
    $dbh->do(q{INSERT INTO test2 (id) VALUES (1), (2), (3)});

    $hd->{inserted} = {
        test1   => [1, 3],
        test2   => [2, 3]
    };

    $hd->delete_all();

    my $res = $dbh->selectall_arrayref(q{SELECT * FROM test1});
    is(@$res, 1);
    is($res->[0][0], 2);

    $res = $dbh->selectall_arrayref(q{SELECT * FROM test2});
    is(@$res, 1);
    is($res->[0][0], 1);
}


