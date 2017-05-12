#!/usr/bin/perl -w
package main;
use strict;
use Data::Dumper;

use DBI;
my $dbh = DBI->connect('dbi:WMI:');

my $sth = $dbh->prepare(<<WQL);
    SELECT * FROM Win32_Process
WQL

$sth->execute();
while (my @row = $sth->fetchrow) {
    my $proc = $row[0];
    print join "\t", $proc->{Caption}, $proc->{ExecutablePath} || "<system>";
    # $proc->Terminate();
    print "\n";
}