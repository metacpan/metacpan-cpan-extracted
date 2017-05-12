BEGIN {
	push @INC, './t';
}

use DBI;
use DBD::Teradata;
use TdTestBigSQL qw(bigsqltest);

use strict;
use warnings;

$| = 1;

my $versnum;
while (substr($ARGV[0], 0, 1) eq '-') {
	my $op = shift @ARGV;
	$versnum = shift @ARGV, next
		if ($op eq '-v');

	$ENV{TDAT_DBD_NO_CLI} = 1,
	next
		if ($op eq '-c');

	$ENV{TDAT_DBD_DEBUG} = 1,
	DBI->trace(2, shift @ARGV),
	next
		if ($op eq '-d');
}

my ($dsn, $userid, $passwd) = @ARGV;

my $dbh = DBI->connect("dbi:Teradata:$dsn", $userid, $passwd) or die $DBI::errstr;

print STDERR "Logon to $dsn ver. " . $dbh->{tdat_version} . '(' . $dbh->{tdat_mode} . " mode) ok.\n";
my $drh = $dbh->{Driver};
print STDERR "DBD::Teradata v. $drh->{Version}\n";

die "Did not connect with CLI adapter, check your configuration."
	unless $dbh->{tdat_uses_cli} || $ENV{TDAT_DBD_NO_CLI};

print STDERR "Connected via ", ($dbh->{tdat_uses_cli} ? 'CLI' : 'pure Perl'), "\n";

$dbh->{tdat_versnum} = $versnum if $versnum;

bigsqltest($dbh);

$dbh->disconnect;

print STDERR "Tests completed OK.\n";