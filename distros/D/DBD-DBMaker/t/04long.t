#!/usr/bin/perl -w -I./t

$|=1;
print "1..$tests\n";

use DBI;
use tests;

print " Test 2: connecting to the database\n";
Check($dbh = MyConnect())
        or DbiError();

open(PROG, $0);				# get some long data for testing
my $longdata='';
while (<PROG>) {
    $longdata .= $_;
}
close(PROG);

#
# Create a test table
#
print " Test 2: create test table\n";
my $table = "perl_test";
sub tab_create {
  my $fields = "A INTEGER, LVB LONG VARBINARY, LVC LONG VARCHAR";
  $dbh->do("DROP TABLE $table");
  $dbh->do("CREATE TABLE $table ($fields)")
}
Check(tab_create())
        or DbiError();

print " Test 3: insert first tuple by execute bind\n";
$sth = $dbh->prepare("INSERT INTO $table(A,LVB) VALUES(:1, :2)");
Check($sth->execute(1, $longdata))
	or DbiError();

print " Test 4: insert second tuple by bind_param\n";
$sth->bind_param(1, 2);
$sth->bind_param(2, $longdata);
Check($sth->execute)
	or DbiError();
$sth->finish();

$dbh->commit();

#------------------------
# is this really there ?
#------------------------
$sth = $dbh->prepare("SELECT A, LVB FROM $table WHERE A=:1", 
	             { 'LongReadLen' => 4096 });
Check($sth->execute(1))
	or DbiError();
Check(@row = $sth->fetchrow())
	or DbiError();
Check($row[1] eq $longdata) or print "Compare fail!\n";
$sth->finish();

#
# 
#
$sth = $dbh->prepare("SELECT A, LVB, LVB FROM $table WHERE A = :1",
                     { 'LongReadLen' => 0 });
$sth->execute(1);
@row=$sth->fetchrow();
my $offset = 100;
my $blob = "";
while ($frag = $sth->blob_read(2, $offset, 100)) {
    $offset += length($frag);
    $blob .= $frag;
}
Check($blob eq $longdata) or print "blob_read fail!\n";
$sth->finish();
#DBI->trace(0);

#
# Test LongTruncOk flag
#
$sth = $dbh->prepare("SELECT A, LVB FROM $table WHERE A=:1",
		     {'LongReadLen' => 64 });
$sth->execute(1);
my ($x, $y);
$sth->bind_columns(undef, \$x, \$y);
if ($sth->fetch()) {
    print " expect string data right truncation error\n";
    print " err, state: ", $sth->err, ",", $dbh->state, "\n";
    print " errstr: ", $dbh->errstr, "\n";
    # print " y: >>", $y, "<<\n";
    # print "longdata: >>", substr($longdata, 0, 64), "<<\n";
    Check($y eq substr($longdata, 0, 64)) or print "Trunc data wrong!\n";
    }

Check(!$sth->err) or print "LongTruncOk flag wrong\n";
$sth->finish();

BEGIN { $tests = 10; }

$dbh->disconnect();
