#!perl -wT

use strict;
use warnings;
use Test::Most tests => 8;
# use Test::NoWarnings;	# FIXME: remove once registration completed

eval 'use autodie qw(:all)';	# Test for open/close failures

STRINGDATA: {
	use_ok('DBI');
	diag("Ignore warnings about unregistered driver and drv_prefix for now");

	my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');

	$dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');
	$dbh->func('person2', 'XML', [<DATA>], 'x_import');

	my $sth = $dbh->prepare("Select email FROM person2 WHERE name = 'Nigel Horne'");
	$sth->execute();
	my @rc = @{$sth->fetchall_arrayref()};
	ok(scalar(@rc) == 1);
	my @row1 = @{$rc[0]};
	ok(scalar(@row1) == 1);
	ok($row1[0] eq 'njh@bandsman.co.uk');

	$sth = $dbh->prepare("Select email FROM person2 WHERE name = 'Bugs Bunny'");
	$sth->execute();
	@rc = @{$sth->fetchall_arrayref()};
	ok(scalar(@rc) == 1);
	@row1 = @{$rc[0]};
	ok(scalar(@row1) == 1);
	ok(!defined($row1[0]));

	$sth = $dbh->prepare("Select name FROM person2");
	$sth->execute();
	@rc = @{$sth->fetchall_arrayref()};
	ok(scalar(@rc) == 3);
}

__DATA__
<?xml version="1.0" encoding="US-ASCII"?>
<table>
	<row id="1">
		<name>Bugs Bunny</name>
	</row>
	<row id="2">
		<name>Nigel Horne</name>
		<email>njh@bandsman.co.uk</email>
	</row>
	<row id="3">
		<name>A N Other</name>
		<email>somebody@example.com</email>
	</row>
</table>
