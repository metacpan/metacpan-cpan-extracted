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
	unshift @data,'';
	push @data,42;

	my @plaindata=grep { !utf8::is_utf8($_) } @data;
	@plaindata or die "OOPS";

	$data_tests = 6*@data+6*@plaindata;
	#diag("Data Tests : $data_tests");
	$tests=1+$data_tests;

	eval "require Test::NoWarnings";
	if (!$@) {
	    $has_test_nowarnings = 1;
	}
	$tests += 1 if $has_test_nowarnings;
	#diag("Total Tests : $tests");
    plan tests => $tests;
}

END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

my $dbh=DBI->connect();
ok(defined($dbh),"DBI connect");

SKIP: {
    skip "Unicode-specific tests disabled - not a unicode build",
        $data_tests if (!$dbh->{odbc_has_unicode});

    if (DBI::neat($dbh->get_info(6)) =~ 'SQORA32') {
        skip "Oracle ODBC driver does not work with these tests",
            $data_tests;
    }

my $dbname=$dbh->get_info(17); # DBI::SQL_DBMS_NAME
SKIP: {
	my ($len,$fromdual,$skipempty);
	if ($dbname=~/Microsoft SQL Server/i) {
		($len,$fromdual,$skipempty)=('LEN','',0);
	} elsif ($dbname=~/Oracle/i) {
		($len,$fromdual,$skipempty)=('LENGTH','FROM DUAL',1);
	} elsif ($dbname=~/PostgreSQL/i) {
		($len,$fromdual,$skipempty)=('LENGTH','',0);
    } elsif ($dbname=~/SQLite/i) {
        ($len,$fromdual,$skipempty)=('LENGTH','',0);
	} elsif ($dbname=~/ACCESS/i) {
		($len,$fromdual,$skipempty)=('LEN','',0);
    } elsif ($dbname =~ /DB2/i) {
        ($len, $fromdual, $skipempty) = ('LENGTH', 'FROM SYSIBM.SYSDUMMY1', 0);
	} else {
		skip "Tests not supported using $dbname",$data_tests;
	}

	$dbh->{RaiseError} = 1;
	$dbh->{'LongTruncOk'}=1;
	$dbh->{'LongReadLen'}=32000;


	foreach my $txt (@data) {
		SKIP: {
			if ($skipempty and ($txt eq '')) {
				skip('Database is known to treat empty strings as NULL in this test',12);
			}
			unless (utf8::is_utf8($txt)) {
				my $sth=$dbh->prepare("SELECT ? as roundtrip, $len(?) as roundtriplen $fromdual");
				ok(defined($sth),"prepare round-trip select statement plaintext");

				# diag(dumpstr($txt));
				$sth->bind_param (1,$txt,SQL_VARCHAR);
				$sth->bind_param (2,$txt,SQL_VARCHAR);
				pass("bind VARCHAR");
				$sth->execute();
				pass("execute");
				my ($t,$tlen)=$sth->fetchrow_array();
				pass('fetch');
				cmp_ok($tlen,'==',length($txt),'length equal');
				utf_eq_ok($t,$txt,'text equal');
			}

			my $sth=$dbh->prepare("SELECT ? as roundtrip, $len(?) as roundtriplen $fromdual");
			ok(defined($sth),"prepare round-trip select statement unicode");

			$sth->bind_param (1,$txt,SQL_WVARCHAR);
			$sth->bind_param (2,$txt,SQL_WVARCHAR);
			pass("bind WVARCHAR");
			$sth->execute();
			pass("execute");
			my ($t,$tlen)=$sth->fetchrow_array();
			pass('fetch');
			cmp_ok($tlen,'==',length($txt),'length equal');
			utf_eq_ok($t,$txt,'text equal');
		}
	}

	$dbh->disconnect;

}
};
exit 0;
