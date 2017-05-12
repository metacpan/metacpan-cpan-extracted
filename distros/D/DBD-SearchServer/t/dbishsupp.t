#!/usr/local/bin/perl -w
use Carp;
use DBI;
use DBD::SearchServer;
use strict;

# DBI::Shell support

my $tests;

BEGIN {
  $tests = 9;
  $ENV{FULSEARCH} = './fultest' if !defined($ENV{FULSEARCH});
  $ENV{FULTEMP} = './fultest' if !defined($ENV{FULTEMP});	
}

print "1..$tests\n";
my $curtest = 1;

my $dbh = DBI->connect('dbi:SearchServer:','','');

print "ok $curtest\n" if defined($dbh);
++$curtest;

my $cur;
$cur = $dbh->table_info;

print "ok $curtest\n" if defined($cur);
++$curtest;

my @row;
my $tables = 0;
while (@row = $cur->fetchrow) {
	$tables++;
}

print "ok $curtest\n" if ($tables >= 1);
++$curtest;

$cur = $dbh->do('validate index test validate table');

print "ok $curtest\n" if defined($cur);
++$curtest;

$dbh->disconnect();

print "ok $curtest\n";
++$curtest;

$dbh = DBI->connect ('dbi:SearchServer:','','');

print "ok $curtest\n" if $dbh;
++$curtest;

$dbh->{AutoCommit} = 1;

print "ok $curtest\n" if ($dbh->{AutoCommit} == 1);
++$curtest;

$dbh->{AutoCommit} = 0;

# must not change to pass test!
print "ok $curtest\n" if ($dbh->{AutoCommit} == 1);
++$curtest;


print "$DBI::errstr\n" if (!$dbh->disconnect());

print "ok $curtest\n" if $dbh;
++$curtest;

exit 0;



