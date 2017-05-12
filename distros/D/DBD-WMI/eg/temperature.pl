#!/usr/bin/perl -w
package main;
use strict;
use lib 'lib';
use DBI;
use Cwd;

my $dbh = DBI->connect('dbi:WMI:');

my $sth = $dbh->prepare(<<WQL);
    SELECT * FROM Win32_Fan
WQL

$sth->execute();
while (defined (my $row = $sth->fetchrow_arrayref())) {
    my $temp = $row->[0];
    print join "\t", $temp->Description;
    print "\n";
}