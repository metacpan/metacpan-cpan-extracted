#!perl -T
use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;
use DBIx::Fast;

my $db = DBIx::Fast->new(
    db     => 't/db/test.db',
    driver => 'SQLite',
    Error  => 0,
    PrintError => 0,
    quote  => '`' );

ok $db->now,'DBIx::Fast now()';

for my $Driver (qw(Pg MariaDB mysql SQLite)) {
    $db->_Driver_dbd($Driver);
    is $db->dbd,$Driver,"_Driver_dbd ".$Driver;
}

$db->_Driver_dbd('NotDriver');
isnt $db->dbd,'NotDriver',"_Driver_dbd NotDriver";

is $db->dbi_args->{quote},'`',"dbi_args quote => '`'";

$db->_set_dbi_args( { args => { RaiseError => 99, PrintError => 99 , AutoCommit => 99 } } );

my $args = $db->dbi_args;

is $args->{args}->{RaiseError},99,"dbi_args RaiseError => 99";
is $args->{args}->{RaiseError},99,"dbi_args PrintError => 99";
is $args->{args}->{RaiseError},99,"dbi_args AutoCommit => 99";

is $db->_check_dsn('dbi:SQLite:dbname=t/db/test.db'),
    'dbi:SQLite:dbname=t/db/test.db',"_check_dsn SQLite";

is $db->_check_dsn('dbi:MariaDB:database=test:host'),
    'dbi:MariaDB:database=test:host',"_check_dsn MariaDB";

is $db->_make_dsn({ driver => 'Pg' , host => 'db_pg' , db => 'test_pg' }),
    "dbi:Pg:database=test_pg:db_pg","_make_dsn DBD::Pg";

is $db->_make_dsn({ driver => 'MariaDB' , host => 'db_mariadb' , db => 'test_mariadb' }),
    "dbi:MariaDB:database=test_mariadb:db_mariadb","_make_dsn DBD::MariaDB";

is $db->_make_dsn({ driver => 'mysql' , host => 'db_mysql' , db => 'test_mysql' }),
    "dbi:mysql:database=test_mysql:db_mysql","_make_dsn DBD::mysql";

is $db->_make_dsn({ driver => 'SQLite' , db => 't/db/test.db' }),
    "dbi:SQLite:dbname=t/db/test.db","_make_dsn DBD::SQLite";

done_testing();
