#!/usr/bin/perl

use strict;

use DBI;

if ($#ARGV < 0) {
    die ("must specify database then action (list, add, del, preview)\n");
}
my $db = shift @ARGV;
my $dbh = DBI->connect_cached("dbi:SQLite:dbname=$db","","", { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

my $action;
my $param;

if ($#ARGV < 0) {
    die ("must specify action (list, add, del, preview)\n");
} else {
    $action = shift @ARGV;
    for ($action) {
	if (/^preview$/) {
	    if ($#ARGV < 0) {
		die ("Must specify jabber id");
	    }
	    my $sql = "SELECT [Group], ContactID, Contact, Subscription FROM RosterPreview WHERE UserID = ?";
	    my ($jid) = @ARGV;
	    my $roster = eval {
	       $dbh->selectall_arrayref($sql,{ Slite=> {} },$jid);
	    };
	    foreach my $item ( @$roster ) {
	        print "Entry: $item->[3]  $item->[2]<$item->[1]> in group $item->[0]\n";
	    }
	} elsif (/^list$/) {
	    my $sql = "SELECT jid, fullname, groupname FROM requiredusers ORDER BY groupname, fullname";
	    my $roster = eval {
	       $dbh->selectall_arrayref($sql,{ Slite=> {} });
	    };
	    foreach my $item ( @$roster ) {
	        print "Entry: $item->[1]<$item->[0]> in group $item->[2]\n";
	    }
	} elsif (/^add$/) {
	    if ($#ARGV < 2) {
		die ("Must specify jabber id, fullname and groupname");
	    }
	    my $sql = "INSERT INTO requiredusers (jid, fullname, groupname) VALUES (?, ?, ?)";
	    my ($jid, $fname, $gname) = @ARGV;
	    print "Adding: $fname<$jid> to group $gname\n";
	    $dbh->do($sql,undef,$jid,$fname,$gname);
	} elsif (/^del$/) {
	    if ($#ARGV < 0) {
		die ("Must specify jabber id");
	    }
	    my $sql = "DELETE FROM requiredusers WHERE jid = ?";
	    my ($jid) = @ARGV;
	    print "Deleting: $jid\n";
	    $dbh->do($sql,undef,$jid);
	} else {
	    die ("Unknown action $action\n");
	}
    }
}

