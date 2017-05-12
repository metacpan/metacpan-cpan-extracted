use strict;
use warnings;

use Data::HandyGen::mysql::TableDef;

use Test::More;
use Test::mysqld;

plan skip_all => 'mysql_install_db not found'
    unless `which mysql_install_db 2>/dev/null`;

main();
done_testing();

exit(0);


sub main {
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or die $Test::mysqld::errstr;

    my $dbh = DBI->connect($mysqld->dsn(dbname => 'test'))
        or die $DBI::errstr;

    test($dbh);
    test_is_auto_increment($dbh);
    
    $dbh->disconnect();
}


sub test {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_0 (
            id integer primary key auto_increment,
            test1 varchar(10) not null
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table_test_0');
    my $col_def = $td->column_def('test1');

    isa_ok($col_def, 'Data::HandyGen::mysql::ColumnDef');
}


sub test_is_auto_increment {
    my ($dbh) = @_;

    $dbh->do(q{
        CREATE TABLE table_test_1 (
            id integer primary key auto_increment,
            test1 integer not null,
            test2 varchar(10) not null
        )
    });

    my $td = Data::HandyGen::mysql::TableDef->new(dbh => $dbh, table_name => 'table_test_1');

    #  'id' has auto_increment attribute.
    my $col_def = $td->column_def('id');
    ok( $col_def->is_auto_increment == 1, 'auto_increment on' );

    #  'test1' and 'test2' don't have auto_increment attribute.
    $col_def = $td->column_def('test1');
    ok( $col_def->is_auto_increment == 0, 'auto_increment off' );

    $col_def = $td->column_def('test2');
    ok( $col_def->is_auto_increment == 0, 'auto_increment off' );

}


