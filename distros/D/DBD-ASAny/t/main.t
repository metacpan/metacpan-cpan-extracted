#!/usr/local/bin/perl
#
# $Id: main.t,v 1.4 1998/05/20 22:38:54 mpeppler Exp $

# Base DBD Driver Test

use lib 'blib/lib';
use lib 'blib/arch';

BEGIN {print "1..11\n";}
END {print "not ok 1\n" unless $loaded;}
use DBI;
$loaded = 1;
print "ok 1\n";

my($switch) = DBI->internal;
#DBI->trace(2); # 2=detailed handle trace

print "Switch: $switch->{'Attribution'}, $switch->{'Version'}\n";

print "Available Drivers: ",join(", ",DBI->available_drivers()),"\n";

my $dbh = DBI->connect("DBI:ASAny:UID=dba;PWD=sql;ENG=asademo;DBF=asademo.db", '', '', {PrintError => 0});

die "Unable to connect to asademo: $DBI::errstr"
    unless $dbh;

my $sth;

($sth = $dbh->prepare("select * from sysusers"))
    and print "ok 2\n"
    or print "not ok 2\n";
if($sth->execute) {
    print "ok 3\n";
    print "Fields: $sth->{NUM_OF_FIELDS}\n";
    print "Names: @{$sth->{NAME}}\n";
    #print "Null:  @{$sth->{NULLABLE}}\n";
    my $rows = 0;
    while(@dat = $sth->fetchrow) {
	++$rows;
	foreach (@dat) {
	    $_ = '' unless $_;
	}
	print "@dat\n";
    }
    ($rows == $sth->rows || $sth->rows < 0 )
	and print "ok 4\n"
	    or print "not ok 4\n";
#    $sth->finish;
}
else {
    print STDERR ($DBI::err, ":\n", $sth->errstr);
    print "not ok 3\nnot ok 4\n";
}
undef $sth;
($sth = $dbh->prepare("select * from sys_users"))
    and print "ok 5\n"
    or print "not ok 5\n";
if($sth->execute) {
    print "not ok 6\n";		# SHOULD FAIL!!!

    while(@dat = $sth->fetchrow) {
	print "@dat\n";
    }
#    $sth->finish;
}
else {
    print "ok 6\n";
    ($DBI::err == -141)
	and print "ok 7\n"
	    or print "not ok 7\n";
#    print STDERR ($DBI::err, ":\n", $sth->errstr);
}
($sth = $dbh->prepare("select * from sysusers"))
    and print "ok 8\n"
    or print "not ok 8\n";
if($sth->execute) {
    print "ok 9\n";
    my @fields = @{$sth->{NAME}};
    my $rows = 0;
    my $d;
    my $ok = 1;
    while($d = $sth->fetchrow_hashref) {
	++$rows;
	foreach (@fields) {
	    if(!exists($d->{$_})) {
		$ok = 0;
	    }
	    my $t = $d->{$_} || '';
	    print "$t ";
	}
	print "\n";
    }
    $ok and print "ok 10\n"
	or print "not ok 10\n";
    ($rows == $sth->rows || $sth->rows < 0)
	and print "ok 11\n"
	    or print "not ok 11\n";
#    $sth->finish;
}
else {
    print STDERR ($DBI::err, ":\n", $sth->errstr);
    print "not ok 9\nnot ok 10\nnot ok 11";
}

undef $sth;

$dbh->{LongReadLen} = 32000;

$dbh->disconnect;


