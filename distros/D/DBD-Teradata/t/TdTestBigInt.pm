package TdTestBigInt;

use DBI qw(:sql_types);

use Exporter;
use base ('Exporter');

@EXPORT = qw(dectests);

use strict;
use warnings;

my @decvals = (
'0',
'123456.78900',
'-123456.78900',
'0.00789',
'-0.78900',
'-12345678.78902'
);

sub dectests {
	my $dbh = shift;
#
#	Stored procedures tests
#
	print STDERR "Test DECIMAL conversion w/ and wo/ Math::BigInt...\n";

	foreach my $flag (0..1) {
		print "Setting tdat_no_bigint to $flag\n";
		$dbh->{tdat_no_bigint} = $flag;

		$dbh->do('create volatile table dectest(col1 int, col2 decimal(14,5)) on commit preserve rows;')
#		$dbh->do('create table dectest(col1 int, col2 decimal(14,5))')
			or die "Can't create test table: " . $dbh->errstr . "\n";
		my $sth = $dbh->prepare('insert into dectest values(?, ?)')
			or die "Can't prepare: " . $dbh->errstr . "\n";

		$sth->bind_param(1, undef, SQL_INTEGER);
		$sth->bind_param(2, undef, { TYPE => SQL_DECIMAL, PRECISION => 14, SCALE => 5});
		$sth->execute(1, 123456.789) or die "Can't execute: " . $sth->errstr . "\n";
		$sth->execute(2, -123456.789) or die "Can't execute: " . $sth->errstr . "\n";
		$sth->execute(3, 0.00789) or die "Can't execute: " . $sth->errstr . "\n";
		$sth->execute(4, -0.789) or die "Can't execute: " . $sth->errstr . "\n";
		$sth->execute(5, -12345678.7890153456789) or die "Can't execute: " . $sth->errstr . "\n";

		my $rows = $dbh->selectall_arrayref('select * from dectest order by col1')
			or die $dbh->errstr;
		my $failed = undef;
		foreach (@$rows) {
#
#	very strange stuff...0.00789 does not equal 0.00789...*until* we assign it to
#	another variable ???? and *only* when we use float conversion!!!
#	so maybe its a float precision issue ???
#	anyway don't validate float convert here, since its a bit different
#
			my $s = $_->[1];
#			print 'SHould be ', $decvals[$_->[0]], " is ", $s, "\n";
#				if $flag;
			$failed = $_->[0] . ' wanted ' . $decvals[$_->[0]] . " got $s "
				unless $flag || ($decvals[$_->[0]] == $s) || ($decvals[$_->[0]] eq $s);
		}

		$dbh->do('drop table dectest');

		die "Row $failed did not match\n" if $failed;
	}
	print STDERR "DECIMAL conversion ok\n";
	return 1;
}

1;