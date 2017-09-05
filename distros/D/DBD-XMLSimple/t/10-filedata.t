#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;
use Test::DatabaseRow;
# use Test::NoWarnings;	# FIXME: remove once registration completed

eval 'use autodie qw(:all)';	# Test for open/close failures
use FindBin qw($Bin);

FILEDATA: {
	use_ok('DBI');
	# diag("Ignore warnings about unregistered driver and drv_prefix for now");

	my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');

	local $Test::DatabaseRow::dbh = $dbh;

	$dbh->func('person', 'XML', "$Bin/../data/person.xml", 'xmlsimple_import');

	my $sth = $dbh->prepare("Select name FROM person WHERE email = 'nobody\@example.com'");
	$sth->execute();
	my @rc = @{$sth->fetchall_arrayref()};
	ok(scalar(@rc) == 1);
	my @row1 = @{$rc[0]};
	ok(scalar(@row1) == 1);
	ok($row1[0] eq 'A N Other');

	all_row_ok(
		sql => "Select name FROM person WHERE email = 'nobody\@example.com'",
		tests => [ name => 'A N Other' ],
		description => 'nobody@example.com is the e-mail address of A N Other',
		check_all_rows => 1,
	);
}
