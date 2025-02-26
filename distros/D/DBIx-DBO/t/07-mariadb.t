use 5.014;
use warnings;

my $dbo;
use lib '.';
use Test::DBO MariaDB => 'MariaDB', try_connect => \$dbo;

# Try to ensure a connection by guessing
$dbo ||= Test::DBO::connect_dbo('test', 'root') || Test::DBO::connect_dbo('test')
    || Test::DBO::connect_dbo('', 'root') || Test::DBO::connect_dbo('')
        or plan skip_all => "Can't connect: $DBI::errstr";

my $quoted_db = $dbo->{dbd_class}->_qi($dbo, $Test::DBO::test_db);
if ($dbo->do("CREATE DATABASE $quoted_db")) {
    Test::DBO::todo_cleanup("DROP DATABASE $quoted_db");
    $dbo->do("USE $quoted_db");
} else {
    my $msg = "Can't create the test database: $DBI::errstr";
    unless ($Test::DBO::test_db = $dbo->selectrow_array('SELECT DATABASE()')) {
        undef $dbo;
        plan skip_all => $msg;
    }
    $quoted_db = $dbo->{dbd_class}->_qi($dbo, $Test::DBO::test_db);
}

plan tests => $Test::DBO::test_count + 8;

# Create the DBO (3 tests)
pass "Connect to MariaDB $quoted_db database";
isa_ok $dbo, 'DBIx::DBO', '$dbo';
ok $dbo->do('SET NAMES utf8'), 'SET NAMES utf8' or diag sql_err($dbo);

# In MariaDB the Schema is the DB
$Test::DBO::test_sch = $Test::DBO::test_db;
$Test::DBO::can{collate} = 'BINARY';
$Test::DBO::can{multi_table_update} = 1;
$Test::DBO::can{auto_increment_id} = 'INT NOT NULL AUTO_INCREMENT PRIMARY KEY';
$Test::DBO::can{truncate} = 1;

my $t = Test::DBO::basic_methods($dbo);
# Pick a random available collation
if (my $collation = $dbo->selectrow_hashref('SHOW TABLE STATUS LIKE ?', undef, scalar($t->name))->{Collation}) {
    if (my $charset = $dbo->selectrow_hashref('SHOW COLLATION LIKE ?', undef, $collation)->{Charset}) {
        note "Table's default character set and collation is '$charset', '$collation'";
        if (my $ci = $dbo->selectall_arrayref('SHOW COLLATION', {Slice => {}})) {
            my @ci = grep $_ ne $collation, map $_->{Collation}, grep $_->{Charset} eq $charset, @$ci;
            $Test::DBO::can{collate} = $ci[int rand @ci];
        }
    }
}
Test::DBO::advanced_table_methods($dbo, $t);
Test::DBO::row_methods($dbo, $t);
my $q = Test::DBO::query_methods($dbo, $t);

# MariaDB CalcFoundRows: (5 tests)
$q->limit(2);
unlike $q->sql, qr/ SQL_CALC_FOUND_ROWS /, "Don't use SQL_CALC_FOUND_ROWS by default in MariaDB";
$dbo->config(CalcFoundRows => 1);
like $q->sql, qr/ SQL_CALC_FOUND_ROWS /, 'Use SQL_CALC_FOUND_ROWS in MariaDB';
$q->found_rows;
is $q->config('LastSQL')->[1], 'SELECT FOUND_ROWS()', 'Use FOUND_ROWS() in MariaDB';
$q->run;
$q->found_rows;
is $q->config('LastSQL')->[1], 'SELECT FOUND_ROWS()', 'Use FOUND_ROWS() in MariaDB after every run';

my $sq = $dbo->query($Test::DBO::test_tbl);
$sq->show({FUNC => 'MAX(?)', COL => 'id'});
$q->where($sq, '=', \7);
ok $q->run, "Don't use SQL_CALC_FOUND_ROWS in subqueries" or diag sql_err($q);
$q->unwhere;

Test::DBO::advanced_query_methods($dbo, $t, $q);
Test::DBO::join_methods($dbo, $t->{Name});

END {
    Test::DBO::cleanup($dbo) if $dbo;
}

