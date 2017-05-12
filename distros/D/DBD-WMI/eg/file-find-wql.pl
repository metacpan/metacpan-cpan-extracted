#!/usr/bin/perl -w
package main;
use strict;
use lib 'lib';
use DBI;
use Cwd;

my $dbh = DBI->connect('dbi:WMI:');

my $cwd = cwd;
$cwd =~ /^([A-Z]:)(.*)$/
    or die "Couldn't extract/split the current directory from '$cwd'";
my ($drive,$path) = ($1,$2);
$path =~ tr[/][\\];
$path .= '\\eg\\';
$path = quotemeta($path);

# Quaduple quoting of backslashes is necessary!
my $sth = $dbh->prepare(<<WQL);
    SELECT Drive, Path, Name FROM CIM_Datafile
    WHERE
        Drive = '$drive'
     AND Path  = '$path'
     AND Extension = 'pl'
WQL

$sth->execute();
while (defined (my $row = $sth->fetchrow_arrayref())) {
    #my $ev = $row->[0];
    print join "\t", @$row;
    #print join "\t", $ev->Drive, $ev->Path, $ev->Name;
    print "\n";
}