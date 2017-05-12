#!perl -w

use Test::More tests => 5;

use File::Spec;
use DBIx::PasswordIniFile;

# Test for connect

local $/ = undef;
open( $fh, '<', File::Spec->catfile('.','t','ANSWERS') ) 
    or BAIL_OUT("Cannot open t/ANSWERS file. Run Makefile.PL to recreate it.\n$!" );
$x = <$fh>;
$answers = eval $x or BAIL_OUT( $@ );
close $fh;


SKIP:
{
    skip( <<"End-Of-Message", 5) if ! $answers->{'do_mysql_tests'};
You choose to skip MySQL tests for deprecated functions.
If this behavior isn\'t what you want, clean and run Makefile.PL, 
answering yes when asked if MySQL tests should be executed.   
End-Of-Message

$ini_file = File::Spec->rel2abs( File::Spec->catfile('.','t','connect.ini') );

$conn = new DBIx::PasswordIniFile( -file => $ini_file );

$db = $conn->connect();
ok( ref($db) eq 'DBI::db', 'connect');

ok( ref($conn->dbh()) eq 'DBI::db', 'dbh');

$conn->disconnect() if $conn->dbh();

$db = $conn->connectCached();
ok( ref($db) eq 'DBI::db', 'connectCached');
$conn->disconnect() if $conn->dbh();

$conn1 = DBIx::PasswordIniFile->getCachedConnection( $ini_file );
ok( ref($conn1) eq 'DBIx::PasswordIniFile', 'getCachedConnection w/ argument');

$cache = DBIx::PasswordIniFile->getCache();
ok( ref($cache) eq 'HASH', 'getCache' );

}
