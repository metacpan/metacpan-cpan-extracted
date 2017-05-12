#!/usr/bin/perl

use Test::More;

use_ok("DBI");
use_ok("DBD::SQLite");

my $dbfile = 'test.db';

unlink $dbfile if -f $dbfile;

####################################################################################################
# first off just via direct DBI to check I have the expected functionality correct

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","aaa","bbb");

ok($dbh->do("create table test (ID INTEGER PRIMARY KEY, Value VARCHAR(20))"), "Created table test");

foreach my $i (1..3) {

	$dbh->do("insert into test (ID, Value) values(NULL, 'Test')");

	my $new_id = $dbh->last_insert_id("", "", "test", "");

	is($new_id, $i, "Got a new_id: $new_id");
}

foreach my $i (4..6) {

	$dbh->do("insert into test (ID, Value) values(NULL, 'Test')");

	my $new_id = $dbh->last_insert_id(undef, undef, "test", undef);

	is($new_id, $i, "Got a new_id: $new_id");
}

foreach my $i (7..9) {

	$dbh->do("insert into test (ID, Value) values(NULL, 'Test')");

	my $new_id = $dbh->last_insert_id(undef, undef, undef, undef);

	is($new_id, $i, "Got a new_id: $new_id");
}

foreach my $i (10..12) {

	$dbh->do("insert into test (ID, Value) values(NULL, 'Test')");

	my $new_id = $dbh->last_insert_id("", "", "", "");

	is($new_id, $i, "Got a new_id: $new_id");
}

foreach my $i (13..15) {

	$dbh->do("insert into test (ID, Value) values(?, ?)", {}, undef, 'Test');

	my $new_id = $dbh->last_insert_id("", "", "", "");

	is($new_id, $i, "Got a new_id: $new_id");
}

ok($dbh->do("drop table test;"), "Dropped table test");

# AUTOINCREMENT is a valid key word, but doesn't make any odds so long as ID field is a Primary Key, which it should be anyway
ok($dbh->do("create table test (ID INTEGER PRIMARY KEY AUTOINCREMENT, Value VARCHAR(20))"), "Created table test");

foreach my $i (1..5) {

	$dbh->do("insert into test (ID, Value) values(NULL, 'Test')");

	my $new_id = $dbh->last_insert_id("", "", "test", "");

	is($new_id, $i, "Got a new_id: $new_id");
}

unlink $dbfile if -f $dbfile;

undef $dbh;

####################################################################################################
# now via DBIx::Foo

use_ok("DBIx::Foo");

$dbh = DBIx::Foo->connect("dbi:SQLite:dbname=$dbfile","aaa","bbb");

ok($dbh->do("create table test (ID INTEGER PRIMARY KEY, Value VARCHAR(20))"), "Created table test");

foreach my $i (1..5) {

	my $new_id = $dbh->do("insert into test (ID, Value) values (NULL, 'Test')");

	is($new_id, $i, "Got a new_id: $new_id");
}

foreach my $i (6..10) {

	my $new_id = $dbh->do("insert into test (ID, Value) values (?, ?)", undef, 'Test');

	is($new_id, $i, "Got a new_id: $new_id");
}

foreach my $i (11..15) {

	my $new_id = $dbh->do("insert into test (Value) values (?)", 'Test');

	is($new_id, $i, "Got a new_id: $new_id");
}

done_testing();
