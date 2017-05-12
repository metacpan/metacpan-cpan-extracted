#!/usr/bin/perl -w
#
#	@(#)$Id: blob04.t,v 57.1 1997/07/29 01:24:32 johnl Exp $ 
#
#	Self-contained Test for Blobs (INSERT & SELECT) for DBD::Sqlflex
#
#	Copyright (C) 1996,1997 Jonathan Leffler

use DBD::SqlflexTest;

# Test install...
$dbh = connect_to_test_database(1);

if (!$dbh->{ix_SqlflexOnLine})
{
	print("1..2\n");
	&stmt_note("# Not Sqlflex-OnLine -- no blob testing\n");
	&stmt_ok(0);
}
else
{
	print("1..14\n");
	&stmt_ok(0);
	$dbh->{ix_AutoErrorReport} = 1;

	$stmt2 = 'CREATE TEMP TABLE DBD_IX_BlobTest2 (I SERIAL UNIQUE, B BYTE IN TABLE, ' .
				'T TEXT IN TABLE)';
	&stmt_test($dbh, $stmt2, 0);

	$stmt3 = 'INSERT INTO DBD_IX_BlobTest2 VALUES(?, ?, ?)';
	&stmt_note("# Testing: \$insert = \$dbh->prepare('$stmt3')\n");
	&stmt_fail() unless ($insert = $dbh->prepare($stmt3));
	&stmt_ok(0);

	$blob2 = "This is a TEXT blob";
	$blob1 = "This is a pseudo-BYTE blob";
	&stmt_note("# Testing: \$insert->execute(34, \$blob1, \$blob2)\n");
	&stmt_fail() unless ($insert->execute(34, $blob1, $blob2));
	&stmt_ok(0);

	$blob2 = "This is also a TEXT blob";
	$blob1 = "This is also a pseudo-BYTE blob";
	&stmt_note("# Testing: \$insert->execute(36, \$blob1, \$blob2)\n");
	&stmt_fail() unless ($insert->execute(36, $blob1, $blob2));
	&stmt_ok(0);

	$blob4 = "This, too, is a TEXT blob";
	$blob3 = "This, too, is a pseudo-BYTE blob";
	&stmt_note("# Testing: \$insert->execute(-9, \$blob4, \$blob3)\n");
	&stmt_fail() unless ($insert->execute(-9, $blob4, $blob3));
	&stmt_ok(0);

	&stmt_note("Testing: \$insert->finish\n");
	&stmt_fail() unless ($insert->finish);
	&stmt_ok(0);

	# Verify that inserted data can be returned
	$stmt4 = 'SELECT * FROM DBD_IX_BlobTest2 ORDER BY I';
	&stmt_note("# Testing\n\$cursor = \$dbh->prepare('$stmt4')\n");
	&stmt_fail() unless ($cursor = $dbh->prepare($stmt4));
	&stmt_ok(0);

	&stmt_note("# Re-testing: \$cursor->execute\n");
	&stmt_fail() unless ($cursor->execute);
	&stmt_ok(0);

	&stmt_note("# Re-testing: \$cursor->fetch\n");
	# Fetch returns a reference to an array!
	while ($ref = $cursor->fetch)
	{
		&stmt_ok(0);
		@row = @{$ref};
		# Verify returned data!
		&stmt_note("# Values returned: ", $#row + 1, "\n");
		for ($i = 0; $i <= $#row; $i++)
		{
			&stmt_note("# Row value $i: $row[$i]\n");
		}
	}

	# Verify data attributes!
	@type = @{$cursor->{TYPE}};
	for ($i = 0; $i <= $#type; $i++) { print ("# Type      $i: $type[$i]\n"); }
	@name = @{$cursor->{NAME}};
	for ($i = 0; $i <= $#name; $i++) { print ("# Name      $i: $name[$i]\n"); }
	@null = @{$cursor->{NULLABLE}};
	for ($i = 0; $i <= $#null; $i++) { print ("# Nullable  $i: $null[$i]\n"); }
	@prec = @{$cursor->{PRECISION}};
	for ($i = 0; $i <= $#prec; $i++) { print ("# Precision $i: $prec[$i]\n"); }
	@scal = @{$cursor->{SCALE}};
	for ($i = 0; $i <= $#scal; $i++) { print ("# Scale     $i: $scal[$i]\n"); }

	$nfld = $cursor->{NUM_OF_FIELDS};
	$nbnd = $cursor->{NUM_OF_PARAMS};
	print("# Number of Columns: $nfld; Number of Parameters: $nbnd\n");

	&stmt_note("# Re-testing: \$cursor->finish\n");
	&stmt_fail() unless ($cursor->finish);
	&stmt_ok(0);

	# FREE the cursor and asociated data
	undef $cursor;
}

&stmt_note("# Testing: \$dbh->disconnect()\n");
&stmt_fail() unless ($dbh->disconnect);
&stmt_ok(0);

&all_ok();
