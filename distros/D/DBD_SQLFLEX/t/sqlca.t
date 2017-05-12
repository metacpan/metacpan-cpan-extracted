#!/usr/bin/perl -w
#
#	@(#)$Id: sqlca.t,v 57.1 1997/07/29 01:24:32 johnl Exp $ 
#
#	Test SQLCA Record Handling for DBD::Sqlflex
#
#	Copyright (C) 1997 Jonathan Leffler

use DBD::SqlflexTest;

# Test install...
$dbh = &connect_to_test_database(1);
print_sqlca($dbh);

&stmt_note("1..7\n");
&stmt_ok();
$table = "dbd_ix_sqlca";

# Create table for testing
stmt_test $dbh, qq{
CREATE TEMP TABLE $table
(
	Col01	SERIAL(1000) NOT NULL,
	Col02	CHAR(20) NOT NULL,
	Col03	DATE NOT NULL,
	Col04	DATETIME NOT NULL YEAR TO FRACTION(5),
	Col05   DECIMAL NOT NULL
)
};
print_sqlca($dbh);

# Insert a row of nulls.
stmt_test $dbh, qq{
INSERT INTO $table VALUES(0, 'Some Value', TODAY, '1998-01-01 12:12:12.1234', 3.14159)
};

print_sqlca($dbh);

$select = "SELECT * FROM $table";

# Check that there is now one row of data
select_some_data $dbh, 1, $select;

# Insert a row of values.
$sth = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
&stmt_fail() unless $sth;
&stmt_ok;
print_sqlca $sth;
&stmt_fail() unless $sth->execute('Another value', 'today', '1997-02-28 00:11:22.55555', 2.8128);
&stmt_ok;
print_sqlca $sth;

# Check that there are now two rows of data
select_some_data $dbh, 2, $select;

&all_ok();
