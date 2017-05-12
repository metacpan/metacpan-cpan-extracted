#!/usr/bin/perl -w

#for when we are invoked from "make test"
use lib "t";

use strict;
use TEST;

use Cache::Static;

#skip DBI tests if it's not in Configuration.pm
unless(Cache::Static::is_enabled("DBI")) {
	warn "skipping tests - DBI not enabled in Configuration.pm\n";
	print "1..1\nok 1\n";
	exit 0;
}

#if we can't load DBI, skip all tests
eval {
	require DBI;
}; if($@) {
	warn "DBI.pm not found, all related tests skipped";
	print "1..1\nok 1\n";
	exit;
}

use Cache::Static::DBI;

sub prompt {
	my ($prompt, $default) = @_;
	print STDERR "$prompt [$default]: ";
	my $line = <>;
	chomp($line);
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	$line = $default unless($line);
	return $line;
}

##just test DBI.pm, not DBI_Util.pm here...

my @ro_statements = (
	"SELECT * FROM test_table WHERE 1",
);

my @statements = (
	"TRUNCATE test_table",
	"INSERT HIGH_PRIORITY IGNORE INTO ".
		"test_table (test_field1, test_field2) VALUES ".
		"(4, 5) ",
	"UPDATE LOW_PRIORITY test_table SET test_field1=77",
	"DELETE QUICK FROM test_table",
	"CREATE TEMPORARY TABLE tmp_test_table ( foo TINYINT )",
	"DROP TEMPORARY TABLE tmp_test_table",
);

print "1..";
print (($#statements+1)*12+9);
print "\n";

#get DSN, user, and password
warn "\nInput db type (e.g. mysql), test database name, user, and pass\n";
my $db_type = prompt("Database Type", 'mysql');
my $db_name = prompt("Database Name", 'scache_test_db');
my $user = prompt("Username", 'root');
my $pass = prompt("Password", '');
my $host = prompt("Host", '127.0.0.1');
my $dsn = "$db_type:$db_name:$host";
### comma needs the below for *BSD - do we?
#my $dsn = "$db_type:$db_name:$host;mysql_local_infile=1";

my $dbh;
eval { $dbh = DBI->connect("dbi:$dsn", $user, $pass); };
ok( "DBI connect information", (!$@ && $dbh) );

#TODO: create the table we're about to use (test_table)
my ($st, $r);
eval { $st = $dbh->prepare('CREATE TABLE `test_table` (
	`test_field1` tinyint(4) default NULL,
	`test_field2` tinyint(4) default NULL
);'); };
eval { $r = $st->execute; };
ok ( "create test_table", !$@  || $@ =~ /Table 'test_table' already exists/ );

my $wdbh;
eval { $wdbh = Cache::Static::DBI->wrap($dbh); };
ok ( "Cache::Static::DBI->wrap", (!$@ && $wdbh) );

my $key = Cache::Static::make_key("DBI dep test key");
ok ( "DBI: make key", 'C/c/a/OmdpSTdTgsoDx8T6rCQ' eq $key );

#create the cache files
my ($sth, $rv);
my $tmp_st = $statements[0];
eval { $sth = $wdbh->prepare($tmp_st); };
ok ( "prepare 0 $tmp_st", (!$@ && $sth) );
eval { $rv = $sth->execute; };
ok ( "execute 0 \"$rv\"", !$@ );

#create cache file for tmp_test_table, then drop the table
$tmp_st = (grep(/CREATE/, grep(/tmp_test_table/, @statements)))[0];
eval { $sth = $wdbh->prepare($tmp_st); };
ok ( "prepare 1 \"$tmp_st\"", (!$@ && $sth) );
eval { $rv = $sth->execute; };
ok ( "execute 1 \"$rv\"", !$@ );
$tmp_st = (grep(/DROP/, grep(/tmp_test_table/, @statements)))[0];
eval { $sth = $wdbh->prepare($tmp_st); };
ok ( "prepare 1 \"$tmp_st\"", (!$@ && $sth) );
eval { $rv = $sth->execute; };
ok ( "execute 1 \"$rv\"", !$@ );

#execute rest of statements in @statements
foreach my $st (@statements) {
	my @t = grep(/test_table/, split(/\s+/, $st));
	my $table_name = $t[0];
	my $db_dep = '_DBI|db|mysql:scache_test_db';
	my $table_dep = "_DBI|table|mysql:scache_test_db|$table_name";
	eval {
		Cache::Static::set($key, "value", [ $db_dep ] );
	};
	ok ( "DBI: set", !$@);
	eval {
			Cache::Static::set($key, "value", [ $table_dep ] );
	};
	ok ( "DBI: set", !$@);

	sleep(1);
	ok ( "get_if_same after set",
		Cache::Static::get_if_same($key, [ $db_dep ] ) );
	ok ( "get_if_same after set (table)",
		Cache::Static::get_if_same($key, [ $table_dep ] ) );

	#invalidate the cache
	eval { $sth = $wdbh->prepare($st); };
	ok ( "prepare 1 \"$st\"", (!$@ && $sth) );
	eval { $rv = $sth->execute; };
	ok ( "execute 1 \"$rv\"", !$@ );

	ok ( "get_if_same after refresh",
		!Cache::Static::get_if_same($key, [ $db_dep ] ) );
	ok ( "get_if_same after refresh (table)",
		!Cache::Static::get_if_same($key, [ $table_dep ] ) );

	eval {
		Cache::Static::set($key, "value", [ $db_dep ] );
	};
	ok ( "DBI: set", !$@);
	eval {
		Cache::Static::set($key, "value", [ $table_dep ] );
	};
	ok ( "DBI: set (table)", !$@);

	sleep(1);
	ok ( "get_if_same after set",
		Cache::Static::get_if_same($key, [ $db_dep ] ) );
	ok ( "get_if_same after set (table)",
		Cache::Static::get_if_same($key, [ $table_dep ] ) );

}
exit 0;
