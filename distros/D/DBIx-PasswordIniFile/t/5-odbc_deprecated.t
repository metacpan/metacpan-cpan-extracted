#!perl

use Test::More tests => 2;

use File::Spec;
use DBIx::PasswordIniFile;

local $/ = undef;
open( $fh, '<', File::Spec->catfile('.','t','ANSWERS') ) 
    or BAIL_OUT("Cannot open t/ANSWERS file. Run Makefile.PL to recreate it.\n$!" );
$x = <$fh>;
$answers = eval $x or BAIL_OUT( $@ );
close $fh;


SKIP:
{
    skip( <<"End-Of-Message", 2) if ! $answers->{'do_odbc_tests'};
You choose to skip ODBC tests for deprecated functions.
If this behavior isn\'t what you want, clean and run Makefile.PL, 
answering yes when asked if ODBC tests should be executed.   
End-Of-Message

    $ini_file = File::Spec->rel2abs( File::Spec->catfile('.','t','odbc.ini') );
    
    # Test for new with driver = ODBC

    $conn = new DBIx::PasswordIniFile( -file => $ini_file );

    ok( ref($conn) eq 'DBIx::PasswordIniFile', 'new driver=ODBC');

    # Test for connect

    $dbh = $conn->connect();
    ok( ref($dbh) eq 'DBI::db', 'connect driver=ODBC');

    $conn->disconnect() if $conn->dbh();
}
