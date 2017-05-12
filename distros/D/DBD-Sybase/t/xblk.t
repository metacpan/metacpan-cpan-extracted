# -*-Perl-*-
# $Id: xblk.t,v 1.11 2005/11/04 18:35:54 mpeppler Exp $
#
#
# Small BLK test script for DBD::Sybase


use lib 't';
use _test;
use strict;

use Test::More tests => 62;

BEGIN { use_ok('DBI');
        use_ok('DBD::Sybase');}


use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

sub cslib_cb {
  my ($layer, $origin, $severity, $number, $errmsg, $osmsg, $usermsg) = @_;

  print "cslib_cb: $layer $origin $severity $number $errmsg\n";
  print "cslib_cb: User Message: $usermsg\n";

  if($number == 36) {
    return 1;
  }
  return 0;
}

$SIG{__WARN__} = sub { print @_; };

DBD::Sybase::set_cslib_cb(\&cslib_cb);

#DBI->trace(5);

my $charset = get_charset($Srv, $Uid, $Pwd);

my $dbh = DBI->connect("dbi:Sybase:server=$Srv;database=$Db;charset=$charset;bulkLogin=1", 
		       $Uid, $Pwd, 
		       {PrintError=>1,
			AutoCommit => 1,});
#			syb_err_handler => sub { local $^W = 0; 
#						 print "@_\n"; 
#						 return 0}});

ok(defined($dbh), 'Connect');

if(!$dbh) {
    warn "No connection - did you set the user, password and server name correctly in PWD?\n";
    for (4 .. 62) {
	ok(1);
    }
    exit(0);
}

SKIP: {
  skip 'No BLK library available.', 59 unless $dbh->{syb_has_blk};

my $rc = $dbh->do("create table #tmp(x numeric(9,0) identity, a1 varchar(20), i int null, n numeric(6,2), d datetime, s smalldatetime, mn money, mn1 smallmoney, b varbinary(8), img image null)");

ok(defined($rc), 'Create table');

test1($dbh);
test2($dbh);
test3($dbh);
test4($dbh);
test5($dbh);
test6($dbh);
test7($dbh);
test8($dbh);
}

sub test1 {
  my $dbh = shift;

  $dbh->begin_work;

#  DBI->trace(4);

  my $sth = $dbh->prepare("insert #tmp values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			  { syb_bcp_attribs => { identity_flag => 0, 
						 identity_column => 1 }});
  ok(defined($sth), 'Prepare #1');

  my @data = ([undef, "one", 123, 123.4, 'Oct 11 2001 11:00', 'Oct 11 2001', 23.456789, 44.23, 'deadbeef', 'x' x 1000],
	      [undef, "two", -1, 123.456, 'Oct 12 2001 11:23', 'Oct 11 2001', 44444444444.34, 44353.44, '0a0a0a0a', 'a' x 100],
	      [undef, "three", undef, 1234.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, 34.23, '20202020', 'z' x 100]);

  my $rc;
  my $i = 1;
  foreach (@data) {
    $_->[8] = pack('H*', $_->[8]);
    $rc = $sth->execute(@$_);
    ok(defined($rc), "Send row $i - test 1");
    ++$i;
  }

  $rc = $dbh->commit();
  ok($rc, 'Commit test 1');
  my $rows = $sth->rows();
  ok($rows == 3, 'Rows test 1');

  $sth->finish;

#  DBI->trace(0);
}

sub test2 {
  my $dbh = shift;
  # Now test conversion failures. None of these rows should get loaded.

  $dbh->begin_work;

  my $sth = $dbh->prepare("insert #tmp values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			  { syb_bcp_attribs => { identity_flag => 0, 
						 identity_column => 1 }});
  ok(defined($sth), 'prepare #2');

  my @data = ([undef, "one b", 123, 123.4, 'feb 29 2001 11:00', 'Oct 11 2001', 23.456789, 44.23, 'deadbeef', 'x' x 100],
	      [undef, "two b", 123456789123456, 123.456, 'Oct 12 2001 11:23', 'Oct 11 2001', 44444444444.34, 44353.44, '0a0a0a0a', 'a' x 100],
	      [undef, "three b", undef, 123456.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, 34.23, '20202020', 'z' x 100],
	      [undef, "four b", undef, 126.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, "34343434343434343434.23", '21212121', 'z' x 100],
	     );

  my $i = 1;
  my $rc;
  foreach (@data) {
    $_->[8] = pack('H*', $_->[8]);
    $rc = $sth->execute(@$_);
    ok(!defined($rc), "Execute row $i, test 2");
    ++$i;
  }
  $rc = $dbh->commit;
  ok($rc, 'Commit test 2');

  my $rows = $sth->rows;
  ok($rows == 0, 'Rows, test 2');

  $sth->finish;
}

# Test explicit identity value inserts.
sub test3 {
  my $dbh = shift;

  $dbh->begin_work;

  my $sth = $dbh->prepare("insert #tmp values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			  { syb_bcp_attribs => { identity_flag => 1, 
						 identity_column => 0 }});
  ok(defined($sth), 'Prepare #3');

  my @data = ([10, "one", 123, 123.4, 'Nov 1 2001 12:00', 'Nov 1 2001', 343434.3333, 34.23, 'deadbeef', 'z' x 100],
	      [11, "two", -1, 123.456, '11/1/2001 12:00', '11/1/2001 11:21', 343434.3333, 34.23, '25252525', 'z' x 100],
	      [12, "three", undef, 123, 'Nov 1 2001 12:00', 'Nov 1 2001', 343434.3333, 34.23, '43434343', 'z' x 100]);
  my $i = 1;
  my $rc;
  foreach (@data) {
    $_->[8] = pack('H*', $_->[8]);
    $rc = $sth->execute(@$_);
    ok(defined($rc), "Execute row $i, test 3");
    ++$i;
  }

  $rc = $dbh->commit;
  ok($rc, 'Commit, test 3');

  my $rows = $sth->rows;
  ok($rows == 3, 'Rows, test 3');

  $sth->finish;
}

# Test for prepare failures
sub test4 {
  my $dbh = shift;

  $dbh->begin_work;

  my $sth = $dbh->prepare("insrt #tmp values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			  { syb_bcp_attribs => { identity_flag => 1, 
						 identity_column => 0 }});
  ok(!defined($sth), 'Prepare #4');
  print $dbh->errstr, "\n";
#  DBI->trace(5);
  my $sth1 = $dbh->prepare("select * from #tmp where foo = ?",
			   { syb_bcp_attribs => { identity_flag => 1, 
						  identity_column => 0 }});
  ok(!defined($sth1), 'Prepare #5');
  my $sth2 = $dbh->prepare("select * from #tmp",
			   { syb_bcp_attribs => { identity_flag => 1, 
						  identity_column => 0 }});
  ok(!defined($sth2), 'Prepare #6');
  print $dbh->errstr, "\n";
}


# Test for missing commit/finish.
sub test5 {
  my $dbh = shift;

  $dbh->begin_work;

  my $sth = $dbh->prepare("insert #tmp values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			  { syb_bcp_attribs => { identity_flag => 0, 
						 identity_column => 1 }});
  ok(defined($sth), 'Prepare test 5');

  my @data = ([undef, "test5 one", 123, 123.4, 'Oct 11 2001 11:00', 'Oct 11 2001', 23.456789, 44.23, 'deadbeef', 'x' x 1000],
	      [undef, "test5 two", -1, 123.456, 'Oct 12 2001 11:23', 'Oct 11 2001', 44444444444.34, 44353.44, '0a0a0a0a', 'a' x 100],
	      [undef, "test5 three", undef, 1234.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, 34.23, '20202020', 'z' x 100]);

  my $rc;
  my $i = 1;
  foreach (@data) {
    $_->[8] = pack('H*', $_->[8]);
    $rc = $sth->execute(@$_);
    ok(defined($rc), "Send row $i - test 5");
    ++$i;
  }

  local $^W = 0;
  $sth->finish;
}

# Test for rollback.
sub test6 {
  my $dbh = shift;

  $dbh->begin_work;

  my $sth = $dbh->prepare("insert #tmp values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			  { syb_bcp_attribs => { identity_flag => 0, 
						 identity_column => 1 }});
  ok(defined($sth), 'Prepare test 6');

  my @data = ([undef, "test6 one", 123, 123.4, 'Oct 11 2001 11:00', 'Oct 11 2001', 23.456789, 44.23, 'deadbeef', 'x' x 1000],
	      [undef, "test6 two", -1, 123.456, 'Oct 12 2001 11:23', 'Oct 11 2001', 44444444444.34, 44353.44, '0a0a0a0a', 'a' x 100],
	      [undef, "test6 three", undef, 1234.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, 34.23, '20202020', 'z' x 100]);

  my $rc;
  my $i = 1;
  foreach (@data) {
    $_->[8] = pack('H*', $_->[8]);
    $rc = $sth->execute(@$_);
    ok(defined($rc), "Send row $i - test 6");
    ++$i;
  }

  $rc = $dbh->rollback;
  ok($rc, 'test 6 rollback');
  $rc = $sth->finish;
  ok($rc, 'test 6 finish');
  $sth = undef;

  $dbh->begin_work;
  my $sth2 = $dbh->prepare("select count(*) from #tmp where a1 like 'test6 %'");
  ok(defined($sth2), 'test 6 prepare select');
  $rc = $sth2->execute;
  ok($rc, 'test 6 execute select');
  my $row = $sth2->fetch;
  ok($row && $row->[0] == 0, 'test 6 row value');
  $sth2->finish;
  $sth2 = undef;
  $dbh->commit;
  
  $dbh->begin_work;

  $sth = $dbh->prepare("insert #tmp values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			  { syb_bcp_attribs => { identity_flag => 0, 
						 identity_column => 1 }});
  ok(defined($sth), 'Prepare test 6 (2)');
  foreach (@data) {
    $_->[8] = pack('H*', $_->[8]);
    $rc = $sth->execute(@$_);
    ok(defined($rc), "Send row $i - test 6");
    ++$i;
  }
  $rc = $dbh->commit;
  ok($rc, 'test 6 commit');
  foreach (@data) {
    $_->[8] = pack('H*', $_->[8]);
    $rc = $sth->execute(@$_);
    ok(defined($rc), "Send row $i - test 6");
    ++$i;
  }

  $rc = $dbh->rollback;
  ok($rc, 'test 6 rollback');
  $rc = $sth->finish;
  ok($rc, 'test 6 finish');
  $sth = undef;

#  DBI->trace(0);
}

sub test7 {
  my $dbh = shift;

  $dbh->{AutoCommit} = 1;

  # Test some of the data in the #tmp table.


  my $sth = $dbh->prepare("select count(*), sum(i), sum(n) from #tmp");
  ok(defined($sth), 'prepare test 7');
  my $rc = $sth->execute;
  ok($rc, 'execute test 7');
  my($c, $i, $n);
  while(my $row = $sth->fetch) {
    ($c, $i, $n) = @$row;
    print "@$row\n";
  }
  ok($c == 9, 'Row count');
  ok($i == 366, 'Sum(i)');
  ok($n == 3333.11, 'Sum(n)');
}

# Turn autocommit off, update some data, then try to run
# a bcp operation.
# This tests to make sure that the AutoCommit/CHAINED mode flip/flop
# happens correctly
sub test8 {
  my $dbh = shift;

  #DBI->trace(4);
  $dbh->begin_work;

  my $sth = $dbh->prepare("update #tmp set i = 20 where i = 123");
  ok(defined($dbh), 'Prepare update test 8');
  my $rc = $sth->execute;
  ok($rc, 'Execute update test 8');
  $sth = undef;

  $sth = $dbh->prepare("insert #tmp values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			  { syb_bcp_attribs => { identity_flag => 0, 
						 identity_column => 1 }});
  ok(defined($sth), 'Prepare test 8');

  my @data = ([undef, "one", 123, 123.4, 'Oct 11 2001 11:00', 'Oct 11 2001', 23.456789, 44.23, 'deadbeef', 'x' x 1000],
	      [undef, "two", -1, 123.456, 'Oct 12 2001 11:23', 'Oct 11 2001', 44444444444.34, 44353.44, '0a0a0a0a', 'a' x 100],
	      [undef, "three", undef, 1234.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, 34.23, '20202020', 'z' x 100]);

  my $i = 1;
  foreach (@data) {
    $_->[8] = pack('H*', $_->[8]);
    $rc = $sth->execute(@$_);
    ok(defined($rc), "Send row $i - test 8");
    ++$i;
  }

  $rc = $dbh->commit();
  ok($rc, 'Commit test 8');
  my $rows = $sth->rows();
  ok($rows == 3, 'Rows test 8');
  
#  $sth->finish;
  $sth = undef;
}

sub get_charset {
    my $srv = shift;
    my $uid = shift;
    my $pwd = shift;

    my $dbh = DBI->connect("dbi:Sybase:server=$srv", $uid, $pwd);
    die "Can't connect to $srv" unless $dbh;

    my $sth = $dbh->prepare("sp_configure 'default character set id'");
    $sth->execute;
    my $id;
    while(my $r = $sth->fetch) {
	$id = $r->[4];
    }
    $sth->finish;
    if(!$id) {
	warn "Can't find charset id - using iso_1";
	return 'iso_1';
    }

    $sth = $dbh->prepare("select name from master..syscharsets where id = $id");
    $sth->execute;
    my $charset;
    while(my $r = $sth->fetch) {
	$charset = $r->[0];
    }
    if(!defined($charset)) {
	warn "Can't find charset name - using iso_1";
	return 'iso_1';
    }

    return $charset;
}
