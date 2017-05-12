#!perl -w
# $Id: 40meta.t 546 2006-11-26 17:51:19Z wagnerch $

use Test::More;
use DBI qw(:sql_types);
use DBD::TimesTen qw(:sql_getinfo_options);
unshift @INC, 't';

$| = 1;
plan tests => 25;


my ($sth, $tmp);

## Connect
my $dbh = DBI->connect();
unless ($dbh)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}


## type_info
my @types = $dbh->type_info(SQL_ALL_TYPES);
cmp_ok(scalar @types, '>=', 17, 'type_info ok');

## tables
my @tables = $dbh->tables();
ok(scalar @tables, 'tables ok');

## sql_dbms_ver
my $sql_dbms_ver = $dbh->get_info(SQL_DBMS_VER);
ok($sql_dbms_ver, 'get_info dbms version ok');

## sql_dbms_name
my $sql_dbms_name = $dbh->get_info(SQL_DBMS_NAME);
ok($sql_dbms_name, 'get_info dbms name ok');

## table_info
my @table_info_params = (
        [ 'schema list',        undef, '%', undef, undef ],
        [ 'type list',          undef, undef, undef, '%' ],
        [ 'table list',         undef, undef, undef, undef ],
);
foreach my $table_info_params (@table_info_params)
{
    my ($name) = shift @$table_info_params;
    my $table_info_sth = $dbh->table_info(@$table_info_params);
    ok($table_info_sth, 'table_info ' . $name . ' ok');
    my $data = $table_info_sth->fetchall_arrayref;
    ok($data, 'fetch ' . $name . ' ok');
    ok(scalar @$data, 'results ' . $name . ' ok');
}

## column_info
my @column_info_params = (
        [ 'schema list',        undef, '%', undef, undef ],
        [ 'column list',        undef, undef, undef, '%' ],
        [ 'table list',         undef, undef, undef, undef ],
);
foreach my $column_info_params (@column_info_params)
{
    my ($name) = shift @$column_info_params;
    my $column_info_sth = $dbh->column_info(@$column_info_params);
    ok($column_info_sth, 'column_info ' . $name . ' ok');
    my $data = $column_info_sth->fetchall_arrayref;
    ok($data, 'fetch ' . $name . ' ok');
    ok(scalar @$data, 'results ' . $name . ' ok');
}

## primary_key_info
my $primary_key_info_sth = $dbh->primary_key_info(undef, 'SYS', 'TABLES');
ok($primary_key_info_sth, 'primary_key_info ok');
$tmp = $primary_key_info_sth->fetchall_arrayref;
ok($tmp, 'fetch ok');
ok(scalar @$tmp, 'results ok');


exit 0;
