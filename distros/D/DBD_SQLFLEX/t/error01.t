#!/usr/bin/perl -w
#
#	@(#)$Id: error01.t,v 57.1 1997/07/29 01:24:32 johnl Exp $ 
#
#	Test error on EXECUTE for DBD::Sqlflex
#
#	Copyright (C) 1997 Jonathan Leffler

use DBD::SqlflexTest;

# Test install...
$dbh = &connect_to_test_database(1);

$tabname = "dbd_ix_err01";

&stmt_note("1..5\n");
&stmt_ok();

stmt_test $dbh, qq{
CREATE TEMP TABLE $tabname
(
	Col01	SERIAL NOT NULL,
	Col02	CHAR(20) NOT NULL
)
};

stmt_test $dbh, qq{ CREATE UNIQUE INDEX pk_$tabname ON $tabname(Col02) };

$insert01 = qq{ INSERT INTO $tabname VALUES(0, 'Gee Whizz!') };

$sth = $dbh->prepare($insert01) or die "Prepare failed\n";

# Should be OK!
$rv = $sth->execute();
stmt_fail() if ($rv != 1);

# Should fail (dup value)!
$rv = $sth->execute();
if (defined $rv)
{
	print "# Return from failed execute = <<$rv>>\n";
	stmt_fail();
}
@isam = @{$sth->{ix_sqlerrd}};
print "# SQL = $sth->{ix_sqlcode}; ISAM = $isam[1]\n";
print "# DBI::state: $DBI::state\n";
print "# DBI::err:   $DBI::err\n";
print "# DBI::errstr:\n$DBI::errstr\n";
stmt_ok();

select_some_data $dbh, 1, "SELECT * FROM $tabname";

all_ok();
