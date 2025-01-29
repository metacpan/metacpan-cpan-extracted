#!perl
use strict;

use DBIx::Fast;
use Test::More;
use Test::Exception;

my $db;

plan( skip_all => 'Skip tests on Windows' ) if $^O eq 'MSWin32';

dies_ok { 1 / 0 } 'Ilegal division 1 / 0';

$db = DBIx::Fast->new( SQLite => 't/db/test.db' );

dies_ok { $db->_dsn_to_dbi('SSS://sql:pass@host:/dbname') } '_dsn_to_dbi : Bad string';
dies_ok { $db->_dsn_to_dbi('sql://user@host/dbname') }      '_dsn_to_dbi : Bad DSN';

$db = DBIx::Fast->new( SQLite => 't/db/test.db' , PrintError => 1 );

dies_ok { DBIx::Fast->new( driver => 'MrTester' ) } 'DBIx::Fast->new( driver => "MrTester" ) dies';

can_ok $db,'Exception';

{
    local $SIG{__WARN__} = sub {
	like($_[0], qr/Exception/, "Exception('Tester')");
    }; $db->Exception('Tester');

    local $SIG{__WARN__} = sub {
	like($_[0], qr/Exception/, "Exception => TableName()");
    }; $db->TableName('("4928');

#    local $SIG{__WARN__} = sub {
#        like($_[0], qr/Exception/, "_check_dsn Failed DBI");
#    }; $db->_check_dsn('dbx:KikoTT:db:bd');

    local $SIG{__WARN__} = sub {
        like($_[0], qr/Exception/, "_check_dsn Failed DataBase");
    }; $db->_check_dsn('dbi:MariaDB::bd');

    local $SIG{__WARN__} = sub {
        like($_[0], qr/Exception/, "_check_dsn Failed Host");
    }; $db->_check_dsn('dbi:MariaDB:db:');
}

done_testing();
