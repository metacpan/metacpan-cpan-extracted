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
    
    $dbh->do(q{
        CREATE TABLE table1 (
            id integer primary key,
            default1 int default 123,
            default2 varchar(10) default 'abc',
            default3 int,
            nullable1 int not null,
            nullable2 int,
            data_type1 text,
            data_type2 char(10),
            data_type3 varchar(10),
            data_type11 date,
            data_type12 datetime,
            data_type13 timestamp,
            data_type14 time,
            data_type15 year,
            data_type21 tinyint,
            data_type22 smallint,
            data_type23 mediumint,
            data_type24 bigint,
            data_type25 float,
            data_type26 double,
            data_type27 decimal,
            data_type28 int,
            data_type29 numeric,
            data_type30 int unsigned,
            length1 varchar(30),
            prec1 numeric(10, 0),
            prec2 numeric(10, 5)
        )
    });
    $dbh->do(q{
        CREATE TABLE table2 (
            id integer primary key auto_increment
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table1');

    for ( qw/ _get_table_definition def / ) {
        my $def = $td->$_();

        is($def->{id}{COLUMN_NAME}, 'id');
        is($def->{id}{COLUMN_KEY}, 'PRI');
        is($def->{id}{EXTRA}, '');
        is($def->{default1}{COLUMN_DEFAULT}, 123);
        is($def->{default2}{COLUMN_DEFAULT}, 'abc');
        is($def->{default3}{COLUMN_DEFAULT}, undef);
        is($def->{nullable1}{IS_NULLABLE}, 'NO');
        is($def->{nullable2}{IS_NULLABLE}, 'YES');
        is($def->{data_type1}{DATA_TYPE}, 'text');
        is($def->{data_type2}{DATA_TYPE}, 'char');
        is($def->{data_type3}{DATA_TYPE}, 'varchar');
        is($def->{data_type11}{DATA_TYPE}, 'date');
        is($def->{data_type12}{DATA_TYPE}, 'datetime');
        is($def->{data_type13}{DATA_TYPE}, 'timestamp');
        is($def->{data_type14}{DATA_TYPE}, 'time');
        is($def->{data_type15}{DATA_TYPE}, 'year');
        is($def->{data_type21}{DATA_TYPE}, 'tinyint');
        is($def->{data_type22}{DATA_TYPE}, 'smallint');
        is($def->{data_type23}{DATA_TYPE}, 'mediumint');
        is($def->{data_type24}{DATA_TYPE}, 'bigint');
        is($def->{data_type25}{DATA_TYPE}, 'float');
        is($def->{data_type26}{DATA_TYPE}, 'double');
        is($def->{data_type27}{DATA_TYPE}, 'decimal');
        is($def->{data_type28}{DATA_TYPE}, 'int');
        is($def->{data_type29}{DATA_TYPE}, 'decimal');      #  numeric = decimal
        like($def->{data_type28}{COLUMN_TYPE}, qr/^int\(\d+\)$/);
        like($def->{data_type30}{COLUMN_TYPE}, qr/^int\(\d+\) unsigned$/);
        is($def->{length1}{CHARACTER_MAXIMUM_LENGTH}, 30);
        is($def->{prec1}{NUMERIC_PRECISION}, 10);
        is($def->{prec1}{NUMERIC_SCALE}, 0);
        is($def->{prec2}{NUMERIC_PRECISION}, 10);
        is($def->{prec2}{NUMERIC_SCALE}, 5);
    }

    $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table2');
    for ( qw/ _get_table_definition def / ) {
        my $def = $td->$_();
        
        is($def->{id}{EXTRA}, 'auto_increment');
    }

    $dbh->disconnect();

    done_testing();
}

