#!perl -wT

use strict;
use warnings;
use Test::Most tests => 14;
use Test::Differences;
use Test::DatabaseRow;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

STRINGDATA: {
	use_ok('DBI');
	# diag("Ignore warnings about unregistered driver and drv_prefix for now");

	my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');

	local $Test::DatabaseRow::dbh = $dbh;
	$dbh->func('people', 'XML', [<DATA>], 'xmlsimple_import');

	my $sth = $dbh->prepare("Select email FROM people WHERE name = 'Nigel Horne'");
	$sth->execute();

	my @rc = @{$sth->fetchall_arrayref()};

	my @expected = ('njh@bandsman.co.uk');
	eq_or_diff(@rc, \@expected, 'Get of valid data succeeds');

	ok(scalar(@rc) == 1);
	my @row1 = @{$rc[0]};
	ok(scalar(@row1) == 1);
	ok($row1[0] eq 'njh@bandsman.co.uk');

	$sth = $dbh->prepare("Select email FROM people WHERE name = 'Bugs Bunny'");
	$sth->execute();
	@rc = @{$sth->fetchall_arrayref()};

	my @empty = (undef);
	eq_or_diff(@rc, \@empty, 'Check we can get empty values');

	ok(scalar(@rc) == 1);
	@row1 = @{$rc[0]};
	ok(scalar(@row1) == 1);
	ok(!defined($row1[0]));

	$sth = $dbh->prepare('Select name FROM people');
	$sth->execute();
	@rc = @{$sth->fetchall_arrayref()};

	my @names = (['Bugs Bunny'], ['Nigel Horne'], ['A N Other']);
	eq_or_diff(\@rc, \@names, 'Check we can get all of the values');

	ok(scalar(@rc) == 3);

	all_row_ok(
		sql => "Select name FROM people",
		description => '3 names in the database',
		results => 3,
	);
	all_row_ok(
		sql => 'Select email FROM people WHERE email IS NOT NULL',
		description => '2 e-mail addresses in the database',
		results => 2,
	);
}

__DATA__
<?xml version="1.0" encoding="US-ASCII"?>
<people>
	<person id="1">
		<name>Bugs Bunny</name>
	</person>
	<person id="2">
		<name>Nigel Horne</name>
		<email>njh@bandsman.co.uk</email>
	</person>
	<person id="3">
		<email>somebody@example.com</email>
		<name>A N Other</name>
	</person>
</people>
