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


    #  Empty argument
    my $td = Data::HandyGen::mysql::TableDef->new();
    isa_ok($td, 'Data::HandyGen::mysql::TableDef');
    is($td->dbh(), undef);
    is($td->table_name(), undef);
    throws_ok { $td->_get_dbh() } qr/dbh is empty. You should set dbh beforehand/;
    throws_ok { $td->_get_table_name() } qr/table_name is empty. You should set table_name beforehand/;
    

    #  Argument is hash
    $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table1');
    isa_ok($td, 'Data::HandyGen::mysql::TableDef');
    isa_ok($td->dbh(), 'DBI::db');
    is($td->table_name(), 'table1');

    my ($_dbh, $_table_name);
    lives_ok { $_dbh = $td->_get_dbh() };
    is( $_dbh, $dbh );  #  Same address
    lives_ok { $_table_name = $td->_get_table_name() };
    is( $_table_name, 'table1' );


    #  Argument is hashref
    $td = Data::HandyGen::mysql::TableDef->new( { dbh => $dbh, table_name => 'table1' } );
    isa_ok($td, 'Data::HandyGen::mysql::TableDef');
    isa_ok($td->dbh(), 'DBI::db');
    is($td->table_name(), 'table1');

    lives_ok { $_dbh = $td->_get_dbh() };
    is( $_dbh, $dbh );  #  Same address
    lives_ok { $_table_name = $td->_get_table_name() };
    is( $_table_name, 'table1' );


    $dbh->disconnect();

    done_testing();
}

