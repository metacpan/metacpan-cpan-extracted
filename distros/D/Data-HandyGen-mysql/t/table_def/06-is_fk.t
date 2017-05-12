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

    test_single_fk($dbh);
    test_multi_col_fk($dbh);
    test_many_fk($dbh);

    $dbh->disconnect();

    done_testing();
}


sub test_single_fk {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE foreign1 (
            id integer primary key
        )
    });
    $dbh->do(q{
        CREATE TABLE table1 (
            id integer primary key auto_increment,
            col1 integer,
            constraint foreign key (col1) references foreign1(id)
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table1');
    is($td->is_fk('id'), undef);
    is_deeply($td->is_fk('col1'), { table => 'foreign1', column => 'id' });

}


sub test_multi_col_fk {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE foreign2 (
            id1 integer,
            id2 integer,
            primary key (id1, id2)
        )
    });
    $dbh->do(q{
        CREATE TABLE table2 (
            id integer primary key auto_increment,
            col1 integer,
            col2 integer,
            constraint foreign key (col1, col2) references foreign2(id1, id2)
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table2');
    is($td->is_fk('id'), undef);
    is_deeply($td->is_fk('col1'), { table => 'foreign2', column => 'id1' });
    is_deeply($td->is_fk('col2'), { table => 'foreign2', column => 'id2' });
    
}


sub test_many_fk {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE foreign3 (
            id1 integer primary key
        )
    });
    $dbh->do(q{
        CREATE TABLE foreign4 (
            id2 integer primary key
        )
    });
    $dbh->do(q{
        CREATE TABLE table3 (
            id integer primary key auto_increment,
            col1 integer,
            constraint foreign key (col1) references foreign3(id1),
            constraint foreign key (col1) references foreign4(id2)
        )
    });
    
    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table3');
    is($td->is_fk('id'), undef);
   
    is(ref($td->is_fk('col1')), 'ARRAY'); 
    my $col1_fk = [ sort { $a->{table} cmp $b->{table} } @{ $td->is_fk('col1') } ];

    is_deeply($col1_fk, [ 
        { table => 'foreign3', column => 'id1' },
        { table => 'foreign4', column => 'id2' }
    ]);
}



