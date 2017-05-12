#!/usr/bin/perl -w -I./t
# based on *Id: 20SqlServer.t 568 2004-11-08 15:12:37Z jurl *

use strict;
use warnings;
use UChelp;

use Test::More;
use DBI qw(:sql_types);

my $has_test_nowarnings;

$|=1;

my $WAIT=0;
my @data;
my $tests;
my $data_tests;
my $other_tests;
BEGIN {
	if ($] < 5.008001) {
		plan skip_all => "Old Perl lacking unicode support";
	} elsif (!defined $ENV{DBI_DSN}) {
		plan skip_all => "DBI_DSN is undefined";
	}

	@data=(
		"hello ASCII: the quick brown fox jumps over the yellow dog",
		"Hello Unicode: german umlauts (\x{00C4}\x{00D6}\x{00DC}\x{00E4}\x{00F6}\x{00FC}\x{00DF}) smile (\x{263A}) hebrew shalom (\x{05E9}\x{05DC}\x{05D5}\x{05DD})",
	);
	push @data,map { "again $_" } @data;
	utf8::is_utf8($data[0]) and die "Perl set UTF8 flag on non-unicode string constant";
	utf8::is_utf8($data[1]) or die "Perl did not set UTF8 flag on unicode string constant";
	utf8::is_utf8($data[2]) and die "Perl set UTF8 flag on non-unicode string constant";
	utf8::is_utf8($data[3]) or die "Perl did not set UTF8 flag on unicode string constant";

	$data_tests=12*@data;
        $other_tests = 7;
        $tests = $other_tests + $data_tests;
	eval "require Test::NoWarnings";
	if (!$@) {
	    $has_test_nowarnings = 1;
	}
	$tests += 1 if $has_test_nowarnings;
        plan tests => $tests,
}

END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

my $dbh=DBI->connect();
ok(defined($dbh),"DBI connect");

SKIP: {
    if (!$dbh->{odbc_has_unicode}) {
        skip "Unicode-specific tests disabled - not a unicode build",
		$data_tests + $other_tests - 1;
    }


my $dbname = $dbh->get_info(17); # DBI::SQL_DBMS_NAME
SKIP: {
	my ($sth,$NVARCHAR);
	if ($dbname=~/Microsoft SQL Server/i) {
		($NVARCHAR)=('NVARCHAR(1000)');
	} elsif ($dbname=~/Oracle/i) {
		($NVARCHAR)=('NVARCHAR2(1000)');
	} elsif ($dbname=~/PostgreSQL/i) {
		($NVARCHAR)=('VARCHAR(1000)');
	} elsif ($dbname=~/ACCESS/i) {
		($NVARCHAR)=('MEMO');
	} elsif ($dbname=~/DB2/i) {
		($NVARCHAR)=('VARGRAPHIC(500)');
	} else {
		skip "Tests not supported using $dbname",
			$data_tests + $other_tests - 1;
	}

	$dbh->{RaiseError} = 1;
	$dbh->{'LongTruncOk'}=1;
	$dbh->{'LongReadLen'}=32000;

	eval {
		local $dbh->{PrintError}=0;
		$dbh->do("DROP TABLE PERL_DBD_TABLE1");
	};
	pass("Drop old test table");

	$dbh->{RaiseError} = 1;

	$dbh->do(<<__SQL__);
CREATE TABLE
	PERL_DBD_TABLE1
	(
		i INTEGER NOT NULL PRIMARY KEY,
		nva $NVARCHAR,
		nvb $NVARCHAR,
		nvc $NVARCHAR
	)
__SQL__

	pass("Create test table");


	# Insert records into the database:
	$sth=$dbh->prepare("INSERT INTO PERL_DBD_TABLE1 (i,nva,nvb,nvc) values (?,?,?,?)");
	ok(defined($sth),"prepare insert statement");
	for (my $i=0; $i<@data; $i++) {
		my ($nva,$nvb,$nvc)=($data[$i]) x 3;
		$sth->bind_param (1, $i, SQL_INTEGER);
		pass("Bind parameter SQL_INTEGER");
		$sth->bind_param (2, $nva);
		pass("Bind parameter default");
		$sth->bind_param (3, $nvb, SQL_WVARCHAR);
		pass("Bind parameter SQL_WVARCHAR");
		$sth->bind_param (4, $nvc, SQL_WVARCHAR);
		pass("Bind parameter SQL_WVARCHAR");
		$sth->execute();
		pass("execute()");
	}
	$sth->finish();

	# Retrieve records from the database, and see if they match original data:
	$sth=$dbh->prepare("SELECT i,nva,nvb,nvc FROM PERL_DBD_TABLE1");
	ok(defined($sth),'prepare select statement');
	$sth->execute();
	pass('execute select statement');
	while (my ($i,$nva,$nvb,$nvc)=$sth->fetchrow_array()) {
		my $info=sprintf("(index=%i, Unicode=%s)",$i,utf8::is_utf8($data[$i]) ? 'on' : 'off');
		pass("fetch select statement $info");
		cmp_ok(utf8::is_utf8($nva),'>=',utf8::is_utf8($data[$i]),"utf8 flag $info col1");
		utf_eq_ok($nva,$data[$i],"value matches $info col1");

		cmp_ok(utf8::is_utf8($nvb),'>=',utf8::is_utf8($data[$i]),"utf8 flag $info col2");
		utf_eq_ok($nva,$data[$i],"value matches $info col2");

		cmp_ok(utf8::is_utf8($nvc),'>=',utf8::is_utf8($data[$i]),"utf8 flag $info col3");
		utf_eq_ok($nva,$data[$i],"value matches $info col3");
	}

	$WAIT && eval {
		print "you may want to look at the table now, the unicode data is damaged!\nHit Enter to continue\n";
		$_=<STDIN>;

	};

	# eval {
	# 	local $dbh->{RaiseError} = 0;
	# 	$dbh->do("DROP TABLE PERL_DBD_TABLE1");
	# };

	$dbh->disconnect;

	pass("all done");
}
};
exit 0;
