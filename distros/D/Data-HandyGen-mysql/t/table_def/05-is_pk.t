#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql::TableDef;


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
    
    $dbh->do(q{
        CREATE TABLE table1 (
            id integer primary key,
            col1 integer
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table1');
    is($td->is_pk('id'), 1);
    is($td->is_pk('col1'), 0);

    $dbh->do(q{
        CREATE TABLE table2 (
            id1 integer,
            id2 integer,
            col1 integer,
            primary key (id1, id2)
        )
    });

    $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table2');
    is($td->is_pk('id1'), 1);
    is($td->is_pk('id2'), 1);
    is($td->is_pk('col1'), 0);

    $dbh->do(q{
        CREATE TABLE table3 (
            id integer,
            col1 integer
        )
    });
    $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table3');
    is($td->is_pk('id'), 0);
    is($td->is_pk('col1'), 0);

    $dbh->disconnect();

    done_testing();
}

