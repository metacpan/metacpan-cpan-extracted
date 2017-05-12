#!/usr/bin/perl -w
package main;
use strict;
use Data::Dumper;
use Win32::OLE qw(in);

use DBI;

my ($machine,$user,$pass) = @ARGV;

my $dbh = DBI->connect("dbi:WMI:$machine",$user,$pass);

my $sth = $dbh->prepare(<<WQL);
    SELECT Caption FROM Win32_Process
WQL

$sth->execute();
while (my @row = $sth->fetchrow()) {
    print join "\t", @row, "\n";
}