####################################################################
# TESTCASE: 		perld_trusted_context.pl
# DESCRIPTION: 	Trusted Context
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

$dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD, {"PrintError" => 0});
check_error("CONNECT");
createDB($dbh);
prepareDB($dbh, "WITH AUTHENTICATION", "INSERT");

$string = "dbi:DB2:DATABASE=$DATABASE; HOSTNAME=$HOSTNAME; PORT=$PORT; PROTOCOL=$PROTOCOL; UID=$AUTHID; PWD=$AUTHPASS;";
$sql_insert = "INSERT INTO $USERID.trusted_table (i1, i2) VALUES (100, 200)";
$sql_update = "UPDATE $USERID.trusted_table set i1 = 2000 WHERE i2 = 20";
$tcu = uc $TCUSER;
$uid = uc $USERID;

# Normal trusted connection test.
$dbh = DBI->connect($string, $AUTHID, $AUTHPASS, {PrintError => 0, "db2_trusted_context" => 1});
check_error("CONNECT");

check_value("CONNECT", "dbh->{db2_trusted_context}", 1);
check_value("CONNECT", "dbh->FETCH(db2_trusted_context)", 1);

check_value("CONNECT", "dbh->{db2_trusted_user}", $AUTHID);
check_value("CONNECT", "dbh->FETCH(db2_trusted_user)", $AUTHID);

$dbh->{"db2_trusted_user"} = $TCUSER;
$dbh->{"db2_trusted_password"} = $TCPASS;

check_value("CONNECT", "dbh->{db2_trusted_user}", $TCUSER);
check_value("CONNECT", "dbh->FETCH(db2_trusted_user)", $TCUSER);

$dbh = DBI->connect($string, $AUTHID, $AUTHPASS, {"PrintError" => 0, "db2_trusted_context" => 1});
check_error("CONNECT");

$dbh->STORE("db2_trusted_user" => $TCUSER);
$dbh->STORE("db2_trusted_password" => $TCPASS);

check_value("CONNECT", "dbh->{db2_trusted_user}", $TCUSER);
check_value("CONNECT", "dbh->FETCH(db2_trusted_user)", $TCUSER);

$sth = $dbh->do($sql_insert);
$sth = $dbh->do($sql_update);
$expMsg = "[IBM][CLI Driver][DB2/LINUXX8664] SQL0551N  \"$tcu\" does not have the privilege to perform operation \"UPDATE\" on object \"$uid.TRUSTED_TABLE\".  SQLSTATE=42501";
check_value("CONNECT", "DBI::errstr", $expMsg, FALSE);

# Test when order of username and password reversed while switching.
$dbh = DBI->connect($string, $AUTHID, $AUTHPASS, {"PrintError" => 0, "db2_trusted_context" => 1});
check_error("CONNECT");

check_value("CONNECT", "dbh->{db2_trusted_context}", 1);
check_value("CONNECT", "dbh->FETCH(db2_trusted_context)", 1);

check_value("CONNECT", "dbh->{db2_trusted_user}", $AUTHID);
check_value("CONNECT", "dbh->FETCH(db2_trusted_user)", $AUTHID);

$dbh->STORE("db2_trusted_password" => $TCPASS);
$dbh->STORE("db2_trusted_user" => $TCUSER);

$sth = $dbh->do($sql_insert);
$expMsg = "[IBM][CLI Driver][DB2/LINUXX8664] SQL20361N  The switch user request using authorization ID \"$tcu\" within trusted context \"CTX\" failed with reason code \"2\".  SQLSTATE=42517";
check_value("CONNECT", "DBI::errstr", $expMsg, FALSE);

# Test for fake username and password.
$dbh = DBI->connect($string, $AUTHID, $AUTHPASS, {"PrintError" => 0, "db2_trusted_context" => 1});
check_error("CONNECT");

check_value("CONNECT", "dbh->{db2_trusted_context}", 1);
check_value("CONNECT", "dbh->FETCH(db2_trusted_context)", 1);

check_value("CONNECT", "dbh->{db2_trusted_user}", $AUTHID);
check_value("CONNECT", "dbh->FETCH(db2_trusted_user)", $AUTHID);

$dbh->STORE("db2_trusted_user" => $fakeuser);
$dbh->STORE("db2_trusted_password" => $fake_password);

check_value("CONNECT", "dbh->{db2_trusted_user}", $fakeuser);
check_value("CONNECT", "dbh->FETCH(db2_trusted_user)", $fakeuser);

$sth = $dbh->do($sql_insert);
$expMsg = "[IBM][CLI Driver][DB2/LINUXX8664] SQL30082N  Security processing failed with reason \"24\" (\"USERNAME AND/OR PASSWORD INVALID\").  SQLSTATE=08001";
check_value("CONNECT", "DBI::errstr", $expMsg, FALSE);

# Test for trusted context when authentication is not required.
$dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD);
check_error("CONNECT");
prepareDB($dbh, "WITHOUT AUTHENTICATION", "UPDATE");

$dbh = DBI->connect($string, $AUTHID, $AUTHPASS, {"PrintError" => 0, "db2_trusted_context" => 1});
check_error("CONNECT");

check_value("CONNECT", "dbh->{db2_trusted_context}", 1);
check_value("CONNECT", "dbh->FETCH(db2_trusted_context)", 1);

check_value("CONNECT", "dbh->{db2_trusted_user}", $AUTHID);
check_value("CONNECT", "dbh->FETCH(db2_trusted_user)", $AUTHID);

$dbh->STORE("db2_trusted_user" => $TCUSER);

check_value("CONNECT", "dbh->{db2_trusted_user}", $TCUSER);
check_value("CONNECT", "dbh->FETCH(db2_trusted_user)", $TCUSER);

$sth = $dbh->do($sql_insert);

$expMsg = "\[IBM\]\[CLI Driver\]\[DB2\/LINUXX8664\] SQL0551N  \"$tcu\" does not have the privilege to perform operation \"INSERT\" on object \"$uid\.TRUSTED_TABLE\"\.  SQLSTATE=42501";
check_value("CONNECT", "DBI::errstr", $expMsg, FALSE);
$sth = $dbh->do($sql_update);

# Dropping the database.
$dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD);#, {"PrintError" => 0});
check_error("CONNECT");
dropDB($dbh);

fvt_end_testcase($testcase, $success);

#Creating database.
sub createDB {
	my ($dbh) = @_;
	
	$sql_drop_table = "DROP TABLE trusted_table";

	$sql_create_table = "CREATE TABLE trusted_table(i1 int,i2 int)";
	$sql_insert = "INSERT INTO trusted_table (i1, i2) VALUES (?, ?)";
	
	$sth = $dbh->do($sql_drop_table);
	$sth = $dbh->do($sql_create_table);
	
	$sth = $dbh->prepare($sql_insert);
	check_error("PREPARE");
	for ($i = 1;$i <= 2;$i++) {
		$sth->execute($i * 10, $i * 20);
		check_error("EXECUTE");
	}
	
	printTable($dbh, (10, 20, 20, 40));
}

# Dropping database.
sub dropDB {
	my ($dbh) = @_;
	
	printTable($dbh, (2000, 20, 20, 40, 100, 200));
	
	$sql_drop_table = "DROP TABLE trusted_table";
	$sql_drop_role = "DROP ROLE role_01";
	$sql_drop_trusted_context = "DROP TRUSTED CONTEXT ctx";
	
	$sth = $dbh->do($sql_drop_table);
	$sth = $dbh->do($sql_drop_trusted_context);
	$sth = $dbh->do($sql_drop_role);
}

# Preparing database.
sub prepareDB {
	my ($dbh, $authType, $grant) = @_;
	
	$sql_drop_role = "DROP ROLE role_01";
	$sql_drop_trusted_context = "DROP TRUSTED CONTEXT ctx";

	$sql_create_role = "CREATE ROLE role_01";
	$sql_create_trusted_context = "CREATE TRUSTED CONTEXT ctx BASED UPON CONNECTION USING SYSTEM AUTHID ";
	$sql_create_trusted_context .= $AUTHID;
	$sql_create_trusted_context .= " ATTRIBUTES (ADDRESS '";
	$sql_create_trusted_context .= $HOSTNAME;
	$sql_create_trusted_context .= "') DEFAULT ROLE role_01 ENABLE WITH USE FOR ";
	$sql_create_trusted_context .= $TCUSER . " ";
	
	$sql_grant_permission = "GRANT " . $grant . " ON TABLE trusted_table TO ROLE role_01";

	$sth = $dbh->do($sql_drop_trusted_context);
	$sth = $dbh->do($sql_drop_role);
	$sth = $dbh->do($sql_create_role);
	$sth = $dbh->do($sql_create_trusted_context . $authType);
	$sth = $dbh->do($sql_grant_permission);
}

sub printTable {
	my ($dbh, @values) = @_;
	
	$sql = "SELECT * FROM trusted_table";
	
	$sth = $dbh->prepare($sql);
	check_error("PREPARE");
	$sth->execute();
	check_error("EXECUTE");
	
	$i = 0;
	while( @row = $sth->fetchrow_array() ) {
		check_value("TABLE DATA", "row[0]", $values[$i], FALSE, TRUE);
		check_value("TABLE DATA", "row[1]", $values[$i + 1], FALSE, TRUE);
		$i = $i + 2;
	}
}
