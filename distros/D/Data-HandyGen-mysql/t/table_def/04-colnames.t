#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
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
            id integer primary key auto_increment,
            col1 varchar(100),
            col2 varchar(200)
        )
    });

    my $table_def = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table1');
    my $colnames = $table_def->colnames();

    is_deeply([sort(@$colnames)], [ qw/ col1 col2 id / ]);

    $dbh->disconnect();

    done_testing();
}

