use strict;
use warnings;

use DBI;
use Test::mysqld;
use Data::HandyGen::mysql::TableDef;

use Test::More;

plan skip_all => 'mysql_install_db not found'
    unless `which mysql_install_db 2>/dev/null`;

main();
exit(0);


sub main {
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or die $Test::mysqld::errstr;

    my $dbh = DBI->connect($mysqld->dsn(dbname => 'test'))
        or die $DBI::errstr;

    test_no_pk($dbh);
    test_single_pk($dbh);
    test_multi_pk($dbh);

    $dbh->disconnect();
    
    done_testing();
}


sub test_no_pk {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_99 (
            pid integer,
            test1 varchar(10) not null
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table_test_99');
    my $pks = $td->pk_columns();

    is_deeply($pks, []);
}


sub test_single_pk {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_0 (
            pid integer primary key,
            test1 varchar(10) not null
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table_test_0');
    my $pks = $td->pk_columns();

    is_deeply($pks, [qw/ pid /]);
}


sub test_multi_pk {
    my ($dbh) = @_;

    #  Normal order
    $dbh->do(q{
        CREATE TABLE table_test_1 (
            pid1 integer not null,
            pid2 integer not null,
            test1 varchar(10) not null,
            primary key (pid1, pid2)
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table_test_1');
    my $pks = $td->pk_columns();

    is_deeply($pks, [qw/ pid1 pid2 /]);


    #  Reverse order
    $dbh->do(q{
        CREATE TABLE table_test_2 (
            pid1 integer not null,
            pid2 integer not null,
            test1 varchar(10) not null,
            primary key (pid2, pid1)
        )
    });

    $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table_test_2');
    $pks = $td->pk_columns();

    is_deeply($pks, [qw/ pid2 pid1 /]);
}

