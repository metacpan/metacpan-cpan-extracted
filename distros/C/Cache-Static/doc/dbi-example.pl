#!/usr/bin/perl -w

use strict;

use Cache::Static::DBI;

### run the following from mysql before trying this code...
#create database scache_test_db;
#use scache_test_db;
#create table test_table ( test_field1 TINYINT, test_field2 TINYINT );

my @statements = (
	"INSERT HIGH_PRIORITY IGNORE INTO ".
		"test_table (test_field1, test_field2) VALUES ".
		"(4, 5) ",
	"UPDATE LOW_PRIORITY test_table SET test_field1=77",
	"DELETE QUICK FROM test_table",
	"TRUNCATE test_table",
	"CREATE TEMPORARY TABLE tmp_test_table ( foo TINYINT )",
	"DROP TEMPORARY TABLE tmp_test_table",
);

my $dbh = DBI->connect("dbi:mysql:scache_test_db", "root", "");
my $wdbh = Cache::Static::DBI->wrap($dbh); 

print_details('dbh'); 
print_details('wdbh'); 

my ($sth, $rv);
foreach my $st (@statements) {
	print "trying st: $st\n";
	$sth = $wdbh->prepare($st);
	$rv = $sth->execute;
	print_details('sth'); 
	print_details('rv'); 
}

sub print_details {
	my $var = shift;
	my $val = eval '$'.$var;
	printf("%-5s: ", $var);
	print "$val\n";
}


