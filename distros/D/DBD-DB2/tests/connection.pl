$USERID=  $ENV{'DB2_USER'};
$lenu = length($USERID);
if($lenu == 0){
print "Environment variables DB2_USER and DB2_PASSWD are not set. Please set it before running test file. Using config file values.\n";
$USERID="uid";
}

$PASSWORD =  $ENV{'DB2_PASSWD'};
$lenp = length($PASSWORD);
if($lenp == 0){
print "Environment variables DB2_USER and DB2_PASSWD are not set. Please set it before running test file. Using config file values.\n";
$PASSWORD="pwd";
}

$PORT=50000;
$HOSTNAME="localhost";
$DATABASE="database";
$PROTOCOL="TCPIP";

$AUTHID="authID";
$AUTHPASS="auth_pass";
$TCUSER="tc_user";
$TCPASS="tc_pass";

$fakedb = "badDB";
$fakeport = $PORT + 1000;
$fakeprotocol = "badProtocol";
$fakehost = "badHost";
$fakeuser = "badID";
$fake_password = "badPassword";
$remotehost = "129.42.58.212";
