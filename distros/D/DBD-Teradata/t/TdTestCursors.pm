package TdTestCursors;

use DBI qw(:sql_types);

use TdTestDataGen qw(collect_recs_each);
use Exporter;
use base ('Exporter');

@EXPORT = qw(init_for_cursors updatable_cursor persistent_cursor rewind_cursor);

use strict;
use warnings;

###################################################
#
#	test updatable cursors
#
###################################################

sub init_for_cursors {
	my ($dbh, $rowcnt) = @_;

	$rowcnt ||= 1000;
	$dbh->do('DELETE FROM alltypetst') or die $dbh->errstr;
	print STDERR "Generating data...\n";
	my $base = 0;
	my $ary = collect_recs_each(\$base, $rowcnt, 0, 0);
	print STDERR "Data generated, starting execution...\n";
	my $ristarted = time;

	my @tuple_status = ();
	my $sth = $dbh->prepare(
'USING (col1 integer,
col2 smallint,
col3 byteint,
col4 char(40),
col5 varchar(200),
col6 float,
col7 decimal(2,1),
col8 decimal(4,2),
col9 decimal(8,4),
col10 FLOAT,
col11 DATE,
col12 TIME,
col13 TIMESTAMP(0))
LOCKING TABLE alltypetst FOR ACCESS
INSERT INTO alltypetst VALUES(:col1, :col2, :col3, :col4, :col5,
:col6, :col7, :col8, :col9, :col10, :col11, :col12, :col13)',
		) || die ("While preparing: " . $dbh->errstr . "\n");

	my $rownum = -1;
	my $rc = $sth->execute_array({
		ArrayTupleStatus => \@tuple_status,
		ArrayTupleFetch => sub {
			$rownum++;
			return undef unless ($rownum < $rowcnt);
			print "\rSending row $rownum..." unless $rownum%100;
			return [ map { $_->[$rownum]; } @$ary ];
			}
		})
		or die ("While executing: " . $sth->errstr . "\n");

	$ristarted = int((time - $ristarted) * 1000)/1000;
	print "$rc rows inserted in $ristarted secs.\n";

	die "Unexpected tuplestatus size " . (scalar @tuple_status) . " ne $rowcnt\n"
		unless (scalar @tuple_status == $rowcnt);

	my $ok = 0;
	$ok += $_
		foreach (@tuple_status);

	die "Unexpected tuplestatus values\n"
		unless ($ok == scalar @tuple_status);

	return $ristarted;
}

sub updatable_cursor {
	my ($dbh, $dsn, $userid, $passwd) = @_;

	print STDERR "Test updatable cursors...\n";

	my $curdbh = DBI->connect("dbi:Teradata:$dsn", $userid, $passwd,
		{
			PrintError => 1,
			RaiseError => 0,
			AutoCommit => 0,
			tdat_mode => 'ANSI',
			tdat_charset => 'UTF8'
		}
	) || die "Can't connect to $dsn: $DBI::errstr. Exiting...\n";

	print STDERR "ANSI Logon ok.\n";
	my $sth = $curdbh->prepare('SELECT * FROM alltypetst WHERE col1 < 1000 FOR CURSOR')
		or die $curdbh->errstr;
	my $updsth = $curdbh->prepare("UPDATE alltypetst SET col3 = 1 WHERE CURRENT OF $sth->{CursorName}")
		or die $curdbh->errstr;
	my $delsth = $curdbh->prepare("DELETE FROM alltypetst WHERE CURRENT OF $sth->{CursorName}")
		or die $curdbh->errstr;

	$sth->execute or die $sth->errstr;
	my ($updcnt, $delcnt, $updthresh, $delthresh) = (0,0,10,10);
	my $row;
	my $rowcnt = 0;
	while ($row = $sth->fetchrow_arrayref) {
		$rowcnt++;
		if ($$row[0]%3 == 0) {
			$updsth->execute or die $updsth->errstr;
			$updcnt++;
			print "Updated $updcnt rows...\n" and $updthresh += 10
				if ($updcnt >= $updthresh);
		}
		elsif ($$row[0]%4 == 0) {
			$delsth->execute or die $delsth->errstr;
			$delcnt++;
			print "Deleted $delcnt rows...\n" and $delthresh += 10
				if ($delcnt >= $delthresh);
		}
	}
	print STDERR "Processed $rowcnt rows\n";
	$curdbh->commit or die $curdbh->errstr;
	$curdbh->{AutoCommit} = 1;
	$sth = $curdbh->prepare('select count(*) from alltypetst');
	$sth->execute || die $sth->errstr;
	$row = $sth->fetchrow_arrayref;
	print "$$row[0] rows after test\n"
		if ($row && defined($$row[0]));
	$curdbh->disconnect;
	print STDERR "Updatable cursors OK.\n";
}
###################################################
#
#	test persistent read-only cursors
#
###################################################
sub persistent_cursor {
	my $dbh = shift;

	$dbh->{AutoCommit} = 0;
	print STDERR "Testing persistent read-only cursors...\n";
	my $sth = $dbh->prepare('SELECT * from alltypetst', { tdat_keepresp => 1 })
		or die $dbh->errstr;
	my $updsth = $dbh->prepare('UPDATE alltypetst SET col2 = 1 WHERE col1 = ?')
		or die $dbh->errstr;
	my ($row, $rowcnt);
	for my $i (0..1) {
		print 'Starting pass ', ($i+1), "\n";
		$rowcnt = 0;
		$sth->execute or die $sth->errstr;
		while ($row = $sth->fetchrow_arrayref) {
			unless ($$row[0]%100) {
				$updsth->execute($$row[0]) or die $updsth->errstr;
				$dbh->commit;
				print STDERR "applied update\n";
			}
			$rowcnt++;
			last if ($rowcnt > 10000);
		}
		print STDERR "processed $rowcnt rows\n";
	}
	$sth->finish;
	$dbh->{AutoCommit} = 1;
	print STDERR "Persistent cursors OK.\n";
}
###################################################
#
#	test cursor rewind
#
###################################################
sub rewind_cursor {
	my $dbh = shift;

	my $sth = $dbh->prepare('select count(*) from alltypetst');
	$sth->execute || die $sth->errstr;
	my $row = $sth->fetchrow_arrayref;
	die "No rows for rewind test\n"
		unless ($row && defined($$row[0]));
	my $rewindrow = $$row[0] >> 1;

#	$dbh->{AutoCommit} = 0;
	print STDERR "Testing cursor rewind...\n";
	$sth = $dbh->prepare('SELECT * from alltypetst', { tdat_keepresp => 1 })
		or die $dbh->errstr;
	my $rc = $sth->execute;
	die $sth->errstr unless $rc;
	print STDERR "Execute returned $rc\n";
	my $rowcnt = 0;
	while ($row = $sth->fetchrow_arrayref) {
		$rowcnt++;
		print STDERR "Rewinding...\n" and
		$sth->tdat_Rewind()
			if ($rowcnt == $rewindrow);
		print STDERR "fetched $rowcnt rows\n" unless $rowcnt%500;
	}
	print STDERR "fetched $rowcnt rows\n";
	$sth->finish;
#	$dbh->commit();
#	$dbh->{AutoCommit} = 1;
	print STDERR "Cursor rewind OK.\n";
}

1;
