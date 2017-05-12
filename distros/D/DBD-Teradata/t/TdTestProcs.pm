package TdTestProcs;

use DBI qw(:sql_types);

use Exporter;
use base ('Exporter');

@EXPORT = qw(sptests);

use strict;
use warnings;

sub sptests {
	my $dbh = shift;
#
#	Stored procedures tests
#
	print STDERR "Test stored procedures...\n";

	$dbh->do('DROP TABLE SPLTEST');
	die $dbh->errstr if ($dbh->err && ($dbh->err != 3807));

	$dbh->do('CREATE TABLE SPLTEST (col1 int, col2 char(20))') or die $dbh->errstr;

	my $rc = $dbh->do('DROP PROCEDURE DbiSPTest');
	die $dbh->errstr
		unless defined($rc) || ($dbh->err == 5495);
	print STDERR $dbh->errstr . "\n"
		if $dbh->err && ($dbh->err == 5495);

	print STDERR "Creating procedure...\n";
	my $sth = $dbh->prepare(
'CREATE PROCEDURE DbiSPTest(IN Parent INTEGER, OUT Child INTEGER,
	INOUT Sibling integer, IN CommentString CHAR(20))
BEGIN
	Declare Level Integer;
	Set Level = Parent;
 -- toss in a comment
	DELETE FROM SPLTEST All;
	WHILE Level < Parent + Sibling DO
		Insert into spltest values(:level, :CommentString);
		Set level = level + 1;
	END WHILE;
	/* and another
	comment */
	Set Child = Level;
END;', { tdat_sp_save => 1 });

	die $dbh->errstr unless $sth;
	$sth->execute or die $sth->errstr;

	my $stmtinfo = $sth->{tdat_stmt_info};
	my $stmthash = $$stmtinfo[1];
#
#	retrieve any compile errors
#
	my $row;
	if ($$stmthash{Warning}) {
		print $$stmthash{Warning}, "\n";
		print $$row[0], "\n"
			while ($row = $sth->fetchrow_arrayref);
	}
	print "Retrieving procedure HELP info...\n";
	$sth = $dbh->prepare('HELP PROCEDURE DBISPTEST') or die $dbh->errstr;
	$sth->execute or die $sth->errstr;
	while ($row = $sth->fetchrow_arrayref) {
		print $sth->{NAME}->[$_], ': ', (defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n"
			foreach (0..$#$row);
		print "\n";
	}

	print "SHOW the procedure...\n";
	$sth = $dbh->prepare('SHOW PROCEDURE DBISPTEST') or die $dbh->errstr;
	$sth->execute or die $sth->errstr;
	while ($row = $sth->fetchrow_arrayref) {
		foreach (0..$#$row) {
			$$row[$_]=~tr/\r/\n/ if defined($$row[$_]);
			print $sth->{NAME}->[$_], ': ', (defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n";
		}
	}
	print "\n";

	print "Execute the procedure...\n";
	$sth = $dbh->prepare('CALL DbiSPTest(?, Child, ?, \'Add another\')') or die $dbh->errstr;
	my ($sibling, $child) = (10, 0);
	$sth->bind_param(1, 50, { TYPE => SQL_INTEGER });
	$sth->bind_col(1, \$child);
	$sth->bind_param_inout(2, \$sibling, 255, SQL_INTEGER);
	$sth->execute or die "Can't CALL: $sth->errstr \n";
	$sth->fetch;
	print "Sibling $sibling , Child $child \n";

	$dbh->do('DROP PROCEDURE DbiSPTest') or die $dbh->errstr;
	print STDERR "Stored procedures OK.\n";
#
#	test large SPs
#
	print STDERR "Test large stored procedures...\n";
	$rc = $dbh->do('DROP TABLE SPLTEST');
	die $dbh->errstr unless (defined($rc) || ($dbh->err == 3807));
	print STDERR $dbh->errstr . "\n" unless defined($rc);

	$dbh->do('CREATE TABLE SPLTEST (col1 int, col2 char(20))') or die $dbh->errstr;
	print "Generating big SP...\n";
	my $bigsp = make_big_sp();

	print "PREPARING big SP...\n";
	$sth = $dbh->prepare($bigsp, { tdat_sp_save => 1});

	if ($sth) {
		print "Creating big SP...\n";
		$rc = $sth->execute;
		die $sth->errstr unless (defined($rc) || ($dbh->err == 3712));

		unless (defined($rc)) {
			print STDERR $sth->errstr . "\n";
			print "Unable to create large procedure due to DBMS limits, skipping tests.\n";
		}
		else {

			$stmtinfo = $sth->{tdat_stmt_info};
			$stmthash = $$stmtinfo[1];
#
#	retrieve the compile errors
#
			if ($$stmthash{Warning}) {
				print $$stmthash{Warning}, "\n";
				print $$row[0], "\n"
					while ($row = $sth->fetchrow_arrayref);
			}

			print "Getting big SP HELP info...\n";
			$sth = $dbh->prepare('HELP PROCEDURE DBISPTEST') or die $dbh->errstr;
			$sth->execute or die $sth->errstr;
			while ($row = $sth->fetchrow_arrayref) {
				print $sth->{NAME}->[$_], ': ', (defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n"
					foreach (0..$#$row);
				print "\n";
			}

			print "Getting big SP SHOW info...\n";
			$sth = $dbh->prepare('SHOW PROCEDURE DBISPTEST') or die $dbh->errstr;

			$sth->execute or die $sth->errstr;
			while ($row = $sth->fetchrow_arrayref) {
				foreach (0..$#$row) {
					$$row[$_]=~s/\r/\n/g if defined($$row[$_]);
					print $sth->{NAME}->[$_], ': ', (defined($$row[$_]) ? $$row[$_] : 'NULL'), "\n";
				}
			}
			print "\n";

			$sth = $dbh->prepare('CALL DbiSPTest(?, Child, ?, \'Add another\')') or die $dbh->errstr;
			($sibling, $child) = (10, 0);
			$sth->bind_param(1, 50, { TYPE => SQL_INTEGER });
			$sth->bind_col(1, \$child);
			$sth->bind_param_inout(2, \$sibling, 255, SQL_INTEGER);
			$sth->execute or die "Can't CALL: $sth->errstr \n";
			$sth->fetch;
			print "Sibling $sibling , Child $child \n";

			$dbh->do('DROP PROCEDURE DbiSPTest') or die $dbh->errstr;
		}
	}
	else {
		print "Unable to create large procedure due to DBMS limits\n";
	}
	print STDERR "Stored procedures OK.\n";
}

sub make_big_sp {
	my $stmt =
'CREATE PROCEDURE DbiSPTest(IN Parent INTEGER, OUT Child INTEGER,
	INOUT Sibling integer, IN CommentString CHAR(20))
BEGIN
	Declare Level Integer;
	Set Level = Parent;
 -- toss in a comment
	DELETE FROM SPLTEST All;
	WHILE Level < Parent + Sibling DO
		Insert into spltest values(:level, :CommentString);
		Set level = level + 1;
	END WHILE;
	/* and another
	comment */
';
	my $pos = length($stmt);
	$stmt .= (' ' x (300000 - $pos));

	my $val = 1000;
	my $str = '';
	while ($pos < 300000) {
		$str = "\tINSERT INTO SPLTEST VALUES($val, 'string to insert');\n";
		$val++;
		substr($stmt, $pos, length($str)) = $str;
		$pos += length($str);
		print "Generated $pos chars...\n" unless ($val%1000);
	}
	$stmt .= 'SET Sibling = Parent;
	SET Child = Level;
	END;';
#	$stmt .= 'END;';
	return $stmt;
}

1;