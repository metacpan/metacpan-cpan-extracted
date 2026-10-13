####################################################################
# TESTCASE: 		perld054_testDefaultChopBlanksSetting.pl
# DESCRIPTION: 		Test default ChopBlanks setting (on)
# EXPECTED RESULT: 	Success
####################################################################

use DBI;
use DBD::DB2;

require 'connection.pl';
require 'perldutl.pl';

($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);
$success = "y";
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", "$USERID", "$PASSWORD", {PrintError => 0});
check_error("CONNECT");

#######################################
# First create table and insert data
#######################################

$dbh->do("DROP TABLE perld017");

$count = $dbh->do(
  'create table perld017 ( c1 char(10), c2 varchar(10), c3 long varchar )' );
check_error( "Create perld017 table" );
if ($DBI::err != 0)
{
  goto end;
}
$sth = $dbh->prepare( "insert into perld017 values (?,?,?)" );
$sth->execute( ( undef, undef, undef ) );
check_error("Insert undef into perld017");
if ($DBI::err != 0)
{
  goto finish;
}
$sth->execute( ( '', '', '' ) );
check_error("Insert '' into perld017");
if ($DBI::err != 0)
{
  goto finish;
}
$sth->execute( ( '          ', '          ', '          ' ) );
check_error("Insert '          ' into perld017");
if ($DBI::err != 0)
{
  goto finish;
}
$sth->execute( ( '1no pad', '1no pad', '1no pad' ) );
check_error("Insert '1no pad' into perld017");
if ($DBI::err != 0)
{
  goto finish;
}
$sth->execute( ( '2pad      ', '2pad      ', '2pad      ' ) );
check_error("Insert '2pad      ' into perld017");
if ($DBI::err != 0)
{
  goto finish;
}
$sth->execute( ( '0123456789', '0123456789', '0123456789' ) );
check_error("Insert '0123456789' into perld017");
if ($DBI::err != 0)
{
  goto finish;
}
$sth->finish;

#***************************************************************************
# Create select statement
#***************************************************************************
$sth = $dbh->prepare( 'SELECT * FROM perld017 order by 1' );
check_error( 'PREPARE' );

print "Testing default ChopBlanks setting (off)\n";
$success = &dofetch($sth, $tcname);
fvt_end_testcase($testcase, $success);
