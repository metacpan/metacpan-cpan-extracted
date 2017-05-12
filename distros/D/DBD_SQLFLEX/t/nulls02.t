#!/usr/bin/perl -w
#
#	@(#)$Id: nulls02.t,v 57.1 1997/07/29 01:24:32 johnl Exp $ 
#
#	Test Null Handling for DBD::Sqlflex
#
#	Copyright (C) 1997 Jonathan Leffler

use DBD::SqlflexTest;

# Test install...
$dbh = &connect_to_test_database(1);

&stmt_note("1..7\n");
&stmt_ok();
$table = "dbd_ix_nulls02";

stmt_test $dbh, "CREATE TEMP TABLE $table(a CHAR(10), b CHAR(10))";

stmt_fail unless
	$sth=$dbh->prepare("INSERT INTO $table(a,b) VALUES (?,?)");
stmt_ok;

$var1=""; $var2="1";
print "# var1 = <<$var1>>, ", (defined $var1) + 0, "\n";
print "# var2 = <<$var2>>, ", (defined $var2) + 0, "\n";
stmt_fail unless $sth->execute($var1,$var2);
stmt_ok;

undef $var1;$var2="2";
print "# var1 = undefined, ", (defined $var1) + 0, "\n";
print "# var2 = <<$var2>>, ", (defined $var2) + 0, "\n";
stmt_fail unless $sth->execute($var1,$var2);
stmt_ok;

$select = "select count(*) from $table ";
stmt_fail unless $sel = $dbh->prepare($select);
stmt_fail unless $sel->execute();
stmt_fail unless (@row = $sel->fetchrow);
print "# TOTAL: ", $row[0], "\n";
stmt_fail unless $row[0] == 2;
stmt_fail unless $sel->finish;
undef $sel;
stmt_ok;

$select .=  "where a is null";
stmt_fail unless $sel = $dbh->prepare($select);
stmt_fail unless $sel->execute();
stmt_fail unless (@row = $sel->fetchrow);
print "# NULLS: ", $row[0], "\n";
stmt_fail unless $row[0] == 1;
stmt_fail unless $sel->finish;
undef $sel;
stmt_ok;

&all_ok();
