#!perl -w
# $Id: thread.t,v 1.5 2005/10/01 13:05:13 mpeppler Exp $
# Test support for threads in DBD::Sybase.

use strict;
use Config qw(%Config);

BEGIN {
    if (!$Config{useithreads} || $] < 5.008) {
	print "1..0 # Skipped: this perl $] not configured to support iThreads\n";
	exit 0;
    }
}

use threads;

use DBI;
use DBD::Sybase;		# REQUIRED!!!

BEGIN {
    if (!DBD::Sybase::thread_enabled()) {
	print "1..0 # Skipped: this DBD::Sybase not configured to support iThreads\n";
	exit 0;
    }
}

use Test::More tests => 10;

use Thread::Queue;

use lib 't';
use _test;

use vars qw($Pwd $Uid $Srv $Db);


($Uid, $Pwd, $Srv, $Db) = _test::get_info();

my $database = getDatabase();
print "Using database $database\n";

my $queue = Thread::Queue->new;

my $rdr = threads->create(\&reader, $queue, $database);
my @thr;
foreach (1 .. 3) {
    push(@thr, threads->create(\&test_it, $queue, $database));
}
my $count = $rdr->join;
my $total = 0;
foreach (@thr) {
    $total += $_->join;
}
is($count, $total);

sub reader {
    my $queue = shift;
    my $db    = shift;

    my $dbh = getDbh($db);
    ok(defined($dbh));
    my $sth = $dbh->prepare("select id from sysobjects");
    ok(defined($sth));
    my $rc = $sth->execute;
    ok($rc);
    my $count = 0;
    while(my $row = $sth->fetch) {
	$queue->enqueue($row->[0]);
	++$count;
    }

    return $count;
}

sub test_it {
    my $queue = shift;
    my $db    = shift;

    my $dbh = getDbh($db);
    ok(defined($dbh));

    my $sth = $dbh->prepare("select name, crdate, instrig, deltrig, type, uid, sysstat, updtrig from sysobjects where id = ?");
    ok(defined($sth));
    my $count = 0;
    my $rc;
    my $tid = threads->tid();
    while(1) {
	my $id = $queue->dequeue_nb;
	last unless(defined($id));
	$rc = $sth->execute($id);
#	ok($rc);
	while(my $row = $sth->fetch) {
	    print "$tid - fetched($id) == $row->[0]\n";
	    ++$count;
	}
    }

    return $count;
}


sub getDbh {
    my $dbname = shift || 'master';
    my $dbh = DBI->connect("dbi:Sybase:$Srv;database=$dbname;timeout=60;loginTimeout=20", $Uid, $Pwd, {PrintError => 1});

    if(!$dbh) {
	warn "No connection - did you set the user, password and server name correctly in PWD?\n";
	for (4 .. 10) {
	    ok(0);
	}
	exit(0);
    }

    return $dbh;
}

sub getDatabase {
    my $dbh = getDbh();
    my $sth = $dbh->prepare("select 1 from master..sysdatabases where name = 'sybsystemprocs'");
    $sth->execute;
    my $database = 'master';
    while(my $row = $sth->fetch) {
	$database = 'sybsystemprocs';
    }

    return $database;
}
