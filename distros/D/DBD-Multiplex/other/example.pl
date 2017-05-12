#!/usr/bin/perl

use strict;

use DBI;
use DBD::mysql;
use DBD::Multiplex;

my ($dsn1, $dsn2, $attr, $u, $p, $dsns, %attr, $dbh, $sth, $hash_ref, @hash_refs);

#---------------------------------------#
$dsn1 = 'dbi:mysql:dbname=test1;host=localhost';
$dsn2 = 'dbi:mysql:dbname=test2;host=localhost';
$attr = 'mx_connect_mode=report_errors;mx_exit_mode=last_result;';
$u = 'root';
$p = '';
#---------------------------------------#

$dsns = join ('|', ($dsn1, $dsn2));
$dsns = join ('#', ($dsns, $attr));
%attr = (
	'mx_connect_mode' => 'report_errors',
	'mx_exit_mode' => 'last_result'
);

#---------------------------------------#
print "\nconnect to all databases and read\n";
#---------------------------------------#

$dbh = DBI->connect("dbi:Multiplex:$dsns", $u, $p);
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $dbh) {
	print "Cannot connect to databases: $DBI::errstr\n";
}
$dbh->{'ChopBlanks'} = 1;

$sth = $dbh->prepare("select * from users where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $sth) {
	print "Statement preparation failed: $DBI::errstr\n";
}

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

@hash_refs = $sth->fetchrow_hashref;

foreach (@hash_refs) {
        print "DBS $$_{'u_id'} $$_{'u_password'} \n";
}

$sth->finish;
$dbh->disconnect; 

#---------------------------------------#
print "\nconnect to all databases and write\n";
#---------------------------------------#

$dbh = DBI->connect("dbi:Multiplex:$dsns", $u, $p, \%attr);
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $dbh) {
	print "Cannot connect to databases: $DBI::errstr\n";
}

$sth = $dbh->prepare("update users set u_password = 'guess' where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
$sth->finish;

$sth = $dbh->prepare("select * from users where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $sth) {
	print "Statement preparation failed: $DBI::errstr\n";
}

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

while ($hash_ref = $sth->fetchrow_hashref) {
	print "DBS $$hash_ref{'u_id'} $$hash_ref{'u_password'} \n";
}

$sth->finish;
$dbh->disconnect;

#---------------------------------------#
print "\nconnect to first database and read\n";
#---------------------------------------#

$dbh = DBI->connect("$dsn1", $u, $p);
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $dbh) {
	print "Cannot connect to database: $DBI::errstr\n";
}
$dbh->{'ChopBlanks'} = 1;

$sth = $dbh->prepare("select * from users where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $sth) {
	print "Statement preparation failed: $DBI::errstr\n";
}

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

while ($hash_ref = $sth->fetchrow_hashref) {
	print "DB1 $$hash_ref{'u_id'} $$hash_ref{'u_password'} \n";
}

$sth->finish;
$dbh->disconnect;

#---------------------------------------#
print "\nconnect to second database and read\n";
#---------------------------------------#

$dbh = DBI->connect("$dsn2", $u, $p);
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $dbh) {
	print "Cannot connect to database: $DBI::errstr\n";
}
$dbh->{'ChopBlanks'} = 1;

$sth = $dbh->prepare("select * from users where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $sth) {
	print "Statement preparation failed: $DBI::errstr\n";
}

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

while ($hash_ref = $sth->fetchrow_hashref) {
	print "DB2 $$hash_ref{'u_id'} $$hash_ref{'u_password'} \n";
}

$sth->finish;
$dbh->disconnect;

#---------------------------------------#
print "\nconnect to first database and write\n";
#---------------------------------------#

$dbh = DBI->connect("$dsn1", $u, $p);
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $dbh) {
	print "Cannot connect to database: $DBI::errstr\n";
}
$dbh->{'ChopBlanks'} = 1;

$sth = $dbh->prepare("update users set u_password = '1234' where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
$sth->finish;

$sth = $dbh->prepare("select * from users where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $sth) {
	print "Statement preparation failed: $DBI::errstr\n";
}

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

while ($hash_ref = $sth->fetchrow_hashref) {
	print "DB1 $$hash_ref{'u_id'} $$hash_ref{'u_password'} \n";
}

$sth->finish;
$dbh->disconnect;

#---------------------------------------#
print "\nconnect to second database and write\n";
#---------------------------------------#

$dbh = DBI->connect("$dsn2", $u, $p);
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $dbh) {
	print "Cannot connect to database: $DBI::errstr\n";
}
$dbh->{'ChopBlanks'} = 1;

$sth = $dbh->prepare("update users set u_password = '5678' where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
$sth->finish;

$sth = $dbh->prepare("select * from users where u_id = 'tom'");
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);
if (! defined $sth) {
	print "Statement preparation failed: $DBI::errstr\n";
}

$sth->execute;
print "Errors: $DBI::err, $DBI::errstr\n" if ($DBI::err || $DBI::errstr);

while ($hash_ref = $sth->fetchrow_hashref) {
	print "DB2 $$hash_ref{'u_id'} $$hash_ref{'u_password'} \n";
}

$sth->finish;
$dbh->disconnect;

print "\n";

1;
