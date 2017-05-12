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
            id integer primary key auto_increment,
            col1 varchar(10) default 'abc'
        ) default charset utf8
    });

    my $td = Data::HandyGen::mysql::TableDef->new( dbh => $dbh, table_name => 'table1' );
    my %exp = (
        id      => {
            table_catalog =>  'def',
            table_schema =>  'test',
            table_name =>  'table1',
            column_name =>  'id',
            ordinal_position =>  1,
            column_default =>  undef,
            is_nullable =>  'NO',
            data_type =>  'int',
            character_maximum_length =>  undef,
            character_octet_length =>  undef,
            numeric_precision   => qr/^\d+$/,
            numeric_scale => 0,
            character_set_name => undef,
            collation_name  => undef,
            column_type => qr/^int/,
            column_key  => 'PRI',
            extra   => 'auto_increment',
            privileges => qr/^[a-z,]+$/,
        },
        col1    => {
            table_catalog =>  'def',
            table_schema =>  'test',
            table_name =>  'table1',
            column_name =>  'col1',
            ordinal_position =>  2,
            column_default =>  'abc',
            is_nullable =>  'YES',
            data_type =>  'varchar',
            character_maximum_length =>  10,
            character_octet_length =>  30,
            numeric_precision   => undef,
            numeric_scale => undef,
            character_set_name => 'utf8',
            collation_name  => qr/^utf8/,
            column_type => qr/^varchar/,
            column_key  => '',
            extra   => '',
            privileges => qr/^[a-z,]+$/,
        },
    );

    for my $col ( qw/ id col1 / ) {
        my $def = $td->def()->{$col};
        my $cd = Data::HandyGen::mysql::ColumnDef->new($col, $def);
        
        for ( keys %{ $exp{$col} } ) {
            my $val;
            lives_ok { $val = $cd->$_() };
            if ( (ref $exp{$col}{$_}) eq 'Regexp' ) {
                like( $val, $exp{$col}{$_} ) 
                    or diag "Not matched";
            }
            else {
                is($val, $exp{$col}{$_})
                    or diag "Not matched . [" , ref $exp{$col}{$_} , "]";
            }
        }

        throws_ok { $cd->invalid() } qr/no such attribute/;
    }


    $dbh->disconnect();

    done_testing();
}

