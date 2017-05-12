#!/usr/bin/perl -w
#
#	@(#)$Id: rows.t,v 57.1 1997/07/29 01:24:32 johnl Exp $ 
#
#	Test $sth->rows1 for DBD::Sqlflex
#
#	Copyright (C) 1997 Jonathan Leffler

use DBD::SqlflexTest;

sub select_row_data
{
	my ($dbh, $num, $stmt) = @_;
	my ($count, $st2) = (0);
	my (@row);

	&stmt_note("# $stmt\n");
	# Check that there is some data
	&stmt_fail() unless ($st2 = $dbh->prepare($stmt));
	&stmt_fail() unless ($st2->execute);
	while  (@row = $st2->fetchrow)
	{
		my($pad, $i) = ("# ", 0);
		for ($i = 0; $i < @row; $i++)
		{
			&stmt_note("$pad$row[$i]");
			$pad = " :: ";
		}
		&stmt_note("\n");
		my($n) = $st2->rows;
		$count++;
		&stmt_note("# rows = $n, count = $count\n");
		&stmt_fail() unless $n = $count;
	}
	&stmt_fail() unless ($count == $num);
	&stmt_fail() unless ($st2->finish);
	undef $st2;
	&stmt_ok();
}

# Test install...
$dbh = &connect_to_test_database(1);

&stmt_note("1..9\n");
&stmt_ok();
$table = "dbd_ix_rows";

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
};  # KBC order of NOT NULL & YTF 

stmt_test $dbh, qq{
INSERT INTO $table VALUES(0, 'Some Value', TODAY, '1998-01-01 12:12:12.12345', 3.14159)  
};         # KBC implement CURRENT?

$select = "SELECT * FROM $table";

# Check that there is now one row of data
select_row_data $dbh, 1, $select;

# Insert a row of values.
$sth = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
&stmt_fail() unless $sth;
&stmt_ok;
&stmt_fail() unless $sth->execute('Another value', 'today', '1997-02-28 00:11:22.55555', 2.8128);
&stmt_ok;
print_sqlca $sth;
$rows = $sth->rows;
print "# ROWS = $rows\n";

# Check that there are now two rows of data
select_row_data $dbh, 2, $select;

$sth = $dbh->prepare("DELETE FROM $table");
&stmt_fail() unless $sth;
&stmt_ok;
&stmt_fail() unless $sth->execute();;
&stmt_ok;
print_sqlca $sth;
$rows = $sth->rows;
print "# ROWS = $rows\n";

&all_ok();
