package TdTestBulkload;

use DBI;
use threads;
use threads::shared;	# so we can share data
use Thread::Queue;	# a thread-safe shared queue
use Time::HiRes qw(time);

use Exporter;
use base ('Exporter');

@EXPORT = qw(load_nb_raw load_nb_vartext load_thrd_raw load_thrd_vartext);

use strict;
use warnings;

use constant TDLD_ROWCNT => 5000;
###################################################
#
#	test multisession nonblock mode with raw input
#
###################################################
sub load_nb_raw {
	my ($dbh, $dsn, $userid, $passwd, $sescnt, $rowcnt) = @_;

	print STDERR "Testing non-blocking multisession with raw input...\n";
	my @dbhs;
	my @sths;
	my @inserts;
	my @states;

	$rowcnt ||= TDLD_ROWCNT;

	foreach (0..$sescnt-1) {
		$dbhs[$_] = DBI->connect("dbi:Teradata:$dsn", $userid, $passwd,
			{
				PrintError => 0,
				RaiseError => 0,
				AutoCommit => 1,
				tdat_charset => 'UTF8',
				tdat_mode => 'TERADATA',
			}
		) || die "Can't connect to $dsn: $DBI::errstr. Exitting...\n";
		$dbhs[$_]->do('set session dateform=integerdate');
	}

	my $drh = $dbh->{Driver};
	$dbh->do('DELETE FROM alltypetst') or die $dbh->errstr;

	my $fh;
	open($fh, '<rawdata.dat');
	binmode $fh;
	my $ristarted = time;

	foreach (0..$#dbhs) {
		$sths[$_] = $dbhs[$_]->prepare(
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
		{
			tdat_raw_in => 'IndicatorMode',
			tdat_nowait => 1
		}) || die ("While preparing on $_ : " . $dbhs[$_]->errstr . "\n");

		$sths[$_]->bind_param(1, readraw($fh)) || die ($sths[$_]->errstr . "\n");
		$sths[$_]->execute or die ("While executing on $_ : " . $sths[$_]->errstr . "\n");
		$states[$_] = 1;
		$inserts[$_] = 1;
	}

	my $i = $sescnt;
	my @outlist;
	my $rows;
	while ($i < $rowcnt) {
		@outlist = $drh->tdat_FirstAvailList(\@dbhs, -1);
		print " While loading data: " . $drh->errstr . "\n" and
		last
			if (scalar(@outlist) == 0);

		foreach (@outlist) {
			next unless $dbhs[$_]->{tdat_active};
			$rows = $sths[$_]->tdat_Realize();
			die ("Realize failed on $_ :" . $sths[$_]->errstr . "\n")
				unless defined($rows);

			$sths[$_]->bind_param(1, readraw($fh)) || die ($sths[$_]->errstr . "\n");
			$i++;
			$sths[$_]->execute or die ("While executing on $_ : " . $sths[$_]->errstr . "\n");
			$inserts[$_]++;
			print "\rInserting row $i" if ($i%100 == 0);
		}
	}

	foreach (0..$#dbhs) {
		next unless $dbhs[$_]->{tdat_active};
		$rows = $sths[$_]->tdat_Realize(undef);
		die ("Realize failed on $_ : " . $sths[$_]->errstr . "\n")
			unless defined($rows);
	}
	print "\n";
	foreach (0..$#dbhs) {
		$dbhs[$_]->disconnect;
		print "Session $_ inserted $inserts[$_] rows.\n";
	}
	close $fh;

	$ristarted = int((time - $ristarted) * 1000)/1000;
	print "$rowcnt rows inserted in $ristarted secs.\n";
	print STDERR "Non-blocking multisession w/ raw input ok.\n";
	return $ristarted;
}

###################################################
#
#	test multisession nonblock mode with vartext input
#
###################################################
sub load_nb_vartext {
	my ($dbh, $dsn, $userid, $passwd, $sescnt, $rowcnt) = @_;
	my @dbhs;
	my @sths;
	my @inserts;
	my @states;

	$rowcnt ||= TDLD_ROWCNT;

	print STDERR "Testing non-blocking multisession with vartext input...\n";
	foreach (0..$sescnt-1) {
		$dbhs[$_] = DBI->connect("dbi:Teradata:$dsn", $userid, $passwd,
			{
				PrintError => 0,
				RaiseError => 0,
				AutoCommit => 1,
				tdat_charset => 'UTF8',
				tdat_mode => 'TERADATA',
			}
		) || die "Can't connect to $dsn: $DBI::errstr. Exitting...\n";
		$dbhs[$_]->do('set session dateform=ansidate');
	}
	my $drh = $dbh->{Driver};
	$dbh->do('DELETE FROM alltypetst') or die $dbh->errstr;

	open(VARTXT, '<:utf8', 'utf8data.txt');

	my $vt;

	my $rvstarted = time;
	foreach (0..$#dbhs) {
		$sths[$_] = $dbhs[$_]->prepare(
'USING (col1 varchar(18),
col2 varchar(12),
col3 varchar(8),
col4 varchar(40),
col5 varchar(200),
col6 varchar(60),
col7 varchar(8),
col8 varchar(14),
col9 varchar(20),
col10 varchar(60),
col11 varchar(10),
col12 varchar(15),
col13 varchar(19))
LOCKING TABLE alltypetst FOR ACCESS
INSERT INTO alltypetst VALUES(:col1, :col2, :col3, :col4, :col5,
:col6, :col7, :col8, :col9, :col10, :col11, :col12, :col13)',
			{
				tdat_vartext_in => '\|',
				tdat_nowait => 1
			}) || die ("While preparing on $_ : " . $dbhs[$_]->errstr . "\n");
		$vt = <VARTXT>;
		chomp $vt;
		$sths[$_]->bind_param(1, $vt) || die ($sths[$_]->errstr . "\n");
		$sths[$_]->execute or die ("While executing on $_ : " . $sths[$_]->errstr . "\n");
		$states[$_] = 1;
		$inserts[$_] = 1;
	}

	my $i = $sescnt;
	my @outlist;
	my $rows;
	while ($i < $rowcnt) {
		@outlist = $drh->tdat_FirstAvailList(\@dbhs, -1);
		print " While loading data: " . $drh->errstr . "\n" and
		last
			unless (scalar @outlist);

		foreach (@outlist) {
			next unless $dbhs[$_]->{tdat_active};
			$rows = $sths[$_]->tdat_Realize();
			die ("Realize failed on $_ :" . $sths[$_]->errstr . "\n")
				unless defined($rows);

			$vt = <VARTXT>;
			chomp $vt;
			$sths[$_]->bind_param(1, $vt) || die ($sths[$_]->errstr . "\n");
			$i++;
			$sths[$_]->execute or die ("While executing on $_ : " . $sths[$_]->errstr . "\n");
			$inserts[$_]++;
			print "\rInserting row $i" if ($i%100 == 0);
		}
	}

	foreach (0..$#dbhs) {
		next unless $dbhs[$_]->{tdat_active};
		$rows = $sths[$_]->tdat_Realize(undef);
		die ("Realize failed on $_ : " . $sths[$_]->errstr . "\n")
			unless defined($rows);
	}
	print "\n";

	foreach (0..$#dbhs) {
		$dbhs[$_]->disconnect;
		print "Session $_ inserted $inserts[$_] rows.\n";
	}
	$rvstarted = int((time - $rvstarted) * 1000)/1000;
	print "$rowcnt rows inserted in $rvstarted secs.\n";
	close VARTXT;
	print STDERR "Non-blocking multisession w/ vartext input ok.\n";
	return $rvstarted;
}

###################################################
#
#	test threaded multisession mode with raw input
#
###################################################
sub load_thrd_raw {
	my ($dsn, $userid, $passwd, $sescnt, $rowcnt) = @_;
	print STDERR "Testing threaded multisession with raw input...\n";
	my @thrds = ();
	$rowcnt ||= TDLD_ROWCNT;
#
#	since thread startup takes a while, and would skew our
#	timing, we'll use a gated approach
#
	my $wqueue = Thread::Queue->new();
	my $rqueue = Thread::Queue->new();
	my $perthrd = int($rowcnt/$sescnt);
	push @thrds, threads->create(\&raw_load_thrd, $_, $dsn, $userid, $passwd,
		$sescnt, $wqueue, $rqueue, $perthrd)
		foreach (0..$sescnt-1);
#
#	wait for each thread to init
#
	$rqueue->dequeue()
		foreach (0..$#thrds);

	my $ristarted = time;
#
#	send GO to everyone
#
	$wqueue->enqueue('GO')
		foreach (0..$#thrds);
#
#	wait for them all to finish
#
	$_->join foreach (@thrds);
	$ristarted = int((time - $ristarted) * 1000)/1000;
	$perthrd *= $sescnt;
	print "$perthrd rows inserted in $ristarted secs.\n";
	print STDERR "Threaded multisession w/ raw input ok.\n";
	return $ristarted;
}
###################################################
#
#	test threaded multisession mode with vartext input
#
###################################################
sub load_thrd_vartext {
	my ($dsn, $userid, $passwd, $sescnt, $rowcnt) = @_;
	print STDERR "Testing threaded multisession with vartext input...\n";
	my @thrds = ();
	$rowcnt ||= TDLD_ROWCNT;

	my $wqueue = Thread::Queue->new();
	my $rqueue = Thread::Queue->new();
	my $perthrd = int($rowcnt/$sescnt);

	push @thrds, threads->create(\&vartext_load_thrd, $_, $dsn, $userid, $passwd,
		$sescnt, $wqueue, $rqueue, $perthrd)
		foreach (0..$sescnt-1);
#
#	wait for each thread to init
#
	$rqueue->dequeue()
		foreach (0..$#thrds);

	my $rvstarted = time;
#
#	send GO to everyone
#
	$wqueue->enqueue('GO')
		foreach (0..$#thrds);
#
#	wait for them all to finish
#
	$_->join foreach (@thrds);

	$rvstarted = int((time - $rvstarted) * 1000)/1000;
	$perthrd *= $sescnt;
	print "$perthrd rows inserted in $rvstarted secs.\n";
	print STDERR "Threaded multisession w/ vartext input ok.\n";
	return $rvstarted;
}

sub raw_load_thrd {
	my ($thrdnum, $dsn, $user, $pass, $skip, $rqueue, $wqueue, $rowcnt) = @_;

	my $dbh = DBI->connect("dbi:Teradata:$dsn", $user, $pass,
		{
			PrintError => 0,
			RaiseError => 0,
			AutoCommit => 1,
			tdat_charset => 'UTF8',
			tdat_mode => 'TERADATA',
		}
	) || die "Thread $thrdnum: Can't connect to $dsn: $DBI::errstr. Exitting...\n";
	$dbh->do('set session dateform=integerdate');

	unless ($thrdnum) {
		$dbh->do('DELETE FROM alltypetst') or die "Thread 0: " . $dbh->errstr;
	}
print "Started thread $thrdnum\n";

	my $fh;
	open($fh, '<rawdata.dat');
	binmode $fh;
#
#	skip the first N records
#
	if ($thrdnum) {
#	print "Skipping $thrdnum records\n";
		readraw($fh) foreach (1..$thrdnum);
	}

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
		{
			tdat_raw_in => 'IndicatorMode'
		}) || die ("Thread $thrdnum: PREPARE failed: " . $dbh->errstr . "\n");
#
#	tell master we're ready
#
	$wqueue->enqueue("OK");
#
#	wait for goahead
#
	my $go = $rqueue->dequeue();
print "Thread $thrdnum running..\n";
	my $rec;
	my $inserts = 0;
	while ($rec = readraw($fh)) {
		$sth->bind_param(1, $rec)
			or die ("Thread $thrdnum: bind failed: " . $sth->errstr . "\n");
		$inserts++;
		print "\rInserting row $inserts" unless $inserts%100;
		$sth->execute or die ("Thread $thrdnum: execute failed: " . $sth->errstr . "\n");
		last if ($inserts >= $rowcnt);
#
#	skip sescnt records between each pass
#
		my $i = 1;
		$i++
			while (($i < $skip) && readraw($fh));
		last unless ($i == $skip);
	}

	close $fh;
	$dbh->disconnect;
	print "Thread $thrdnum inserted $inserts rows.\n";
}

sub vartext_load_thrd {
	my ($thrdnum, $dsn, $user, $pass, $skip, $rqueue, $wqueue, $rowcnt) = @_;

	my $dbh = DBI->connect("dbi:Teradata:$dsn", $user, $pass,
		{
			PrintError => 0,
			RaiseError => 0,
			AutoCommit => 1,
			tdat_charset => 'UTF8',
			tdat_mode => 'TERADATA',
		}
	) || die "Thread $thrdnum: Can't connect to $dsn: $DBI::errstr. Exitting...\n";

	$dbh->do('set session dateform=integerdate');

	unless ($thrdnum) {
		$dbh->do('DELETE FROM alltypetst') or die "Thread 0: " . $dbh->errstr;
	}

	my $fh;
	open($fh, '<:utf8', 'utf8data.txt');
#
#	skip the first N records
#
	my $rec;
	if ($thrdnum) {
		$rec = <$fh> foreach (1..$thrdnum);
	}

	my $sth = $dbh->prepare(
'USING (col1 varchar(18),
col2 varchar(12),
col3 varchar(8),
col4 varchar(40),
col5 varchar(200),
col6 varchar(60),
col7 varchar(8),
col8 varchar(14),
col9 varchar(20),
col10 varchar(60),
col11 varchar(20),
col12 varchar(15),
col13 varchar(19))
LOCKING TABLE alltypetst FOR ACCESS
INSERT INTO alltypetst VALUES(:col1, :col2, :col3, :col4, :col5,
:col6, :col7, :col8, :col9, :col10, :col11, :col12, :col13)',
		{
			tdat_vartext_in => '\|'
		}) || die ("Thread $thrdnum: PREPARE failed: " . $dbh->errstr . "\n");
#
#	tell master we're ready
#
	$wqueue->enqueue("OK");
#
#	wait for goahead
#
	$rqueue->dequeue;
	my $inserts = 0;
	while (<$fh>) {
		chop;
		$sth->bind_param(1, $_)
			or die ("Thread $thrdnum: bind failed: " . $sth->errstr . "\n");
		$inserts++;
		print "\rInserting row $inserts" unless $inserts%100;
		$sth->execute or die ("Thread $thrdnum: execute failed: " . $sth->errstr . "\n");
		last if ($inserts >= $rowcnt);
#
#	skip sescnt records between each pass
#
		my $i = 1;
		$i++
			while (($i < $skip) && <$fh>);
		last unless ($i == $skip);
	}

	close $fh;
	$dbh->disconnect;
	print "Thread $thrdnum inserted $inserts rows.\n";
}

sub readraw {
	my ($fh) = @_;
	my $len;
	read $fh, $len, 2, 0;
	unless ($len) {
		return undef;
	}
	$len = unpack('S', $len);
	if ($len > 350) {
		print STDERR "Bad len $len\n";
	}
	my $var;
	read $fh, $var, $len+1, 0;
	unless ($var) {
		return undef;
	}
	return pack('S a*', $len, $var);
}

1;