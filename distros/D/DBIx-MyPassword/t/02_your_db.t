#!/usr/bin/perl

use warnings;
use strict;
use Test::Simple tests => 3;
use Text::CSV;

my $NUM_TESTS = 3;
my $file = '.mypassword';

if($ENV{MP_DBUSER} and $ENV{MP_DBDS}) {
	my (@uno) = ($ENV{MP_DBUSER},
	             $ENV{MP_DBUSER}, 
		     ($ENV{MP_DBPASS} || ''),
		     ($ENV{MP_DBDS}   || ''),
		     ($ENV{MP_DBOPTS} || ''),);

	#--> 1) Sort-of a test... write a password file
	my $csv = new Text::CSV;
	open(FILE,">$file") or die("Unable to open $file");
	$csv->combine(@uno);
	print FILE $csv->string(),"\n";
	close FILE;
	ok(-e $file);
	
	#--> 2) Test loading the module
	eval "use DBIx::MyPassword qw($file);";
	ok($@ eq '');
	
	#--> 3) Create a database handle
	my $dbh = DBIx::MyPassword->connect($ENV{MP_DBUSER});
	ok(defined $dbh);
	
	$dbh->disconnect();
	unlink $file;
	
} else {
	ok (1) for(1..$NUM_TESTS);
}
