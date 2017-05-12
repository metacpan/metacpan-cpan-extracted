#!perl -w
use Test::More;

use strict;
use DBI qw(:sql_types);
use Data::Dumper;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my $dbh = DBI->connect($dsn, $dbuser, '', {PrintError => 0 });

if ($dbh) {
    plan tests=>21;
    $dbh->{RaiseError} = 1;
} else {
    plan skip_all => "Unable to connect to Oracle";
}

note("type_info_all\n");
my @types = $dbh->type_info(SQL_ALL_TYPES);
ok(@types >= 8, 'more than 8 types');
note(Dumper( @types ));

note("tables():\n");
my @tables = $dbh->tables;
note(@tables." tables\n");
ok(scalar @tables, 'tables');

my @table_info_params = (
	[ 'schema list',	undef, '%', undef, undef ],
	[ 'type list',   	undef, undef, undef, '%' ],
	[ 'table list',   	undef, undef, undef, undef ],
);
foreach my $table_info_params (@table_info_params) {
    my ($name) = shift @$table_info_params;
    my $start = time;
    note("$name: table_info(".DBI::neat_list($table_info_params).")\n");
    my $table_info_sth = $dbh->table_info(@$table_info_params);
    ok($table_info_sth, 'table_info');
    my $data = $table_info_sth->fetchall_arrayref;
    ok($data, 'table_info fetch');
    ok(scalar @$data, 'table_info data returned');
    my $dur = time - $start;
    note("$name: ".@$data." rows, $dur seconds\n");
}

my $sql_dbms_version = $dbh->get_info(18);
ok($sql_dbms_version, 'dbms_version');
note "sql_dbms_version=$sql_dbms_version";
like($sql_dbms_version, qr/^\d+\.\d+\.\d+$/, 'matched');

# test long DEFAULT from column_info
SKIP: {
    my $table = "dbd_ora__drop_me" . ($ENV{DBD_ORACLE_SEQ}||'');

    eval { $dbh->do("DROP TABLE $table") };

    my $created = eval { $dbh->do("CREATE TABLE $table (testcol NUMBER(15) DEFAULT to_number(decode(substrb(userenv('CLIENT_INFO'),1,1),' ', null,substrb(userenv('CLIENT_INFO'),1,10))))") };

    skip 'could not create test table', 8 unless $created;

    is $dbh->{LongReadLen}, 80, 'LongReadLen is at default';

    ok((my $sth = $dbh->column_info(undef, '%', uc($table), '%')), 'column_info sth');

    is $dbh->{LongReadLen}, 80, 'LongReadLen still at default';

    ok((my $info = eval { $sth->fetchrow_hashref }), 'sth->fetchrow_hashref lived')
        or diag $@;

    is $info->{COLUMN_DEF}, "to_number(decode(substrb(userenv('CLIENT_INFO'),1,1),' ', null,substrb(userenv('CLIENT_INFO'),1,10)))", 'long DEFAULT matched';

    ok($sth->finish, 'sth->finish');

    is $dbh->{LongReadLen}, 80, 'LongReadLen still at default';

    ok($dbh->do("DROP TABLE $table"), 'drop table');
}

$dbh->disconnect;

exit 0;

