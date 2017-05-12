BEGIN {
	push @INC, './t';
	$ENV{TDAT_DBD_NO_CLI} = 1;
	$ENV{TDAT_DBD_DEBUG} = 1;
}

use DBI;
use DBD::Teradata;
use TdTestBigInt qw(dectests);

use strict;
use warnings;

$| = 1;

DBI->trace(2, 'bigint.log');

my $dbh;
my ($dsn, $userid, $passwd) = @ARGV;

$dbh = DBI->connect("dbi:Teradata:$dsn", $userid, $passwd,
	{
		PrintError => 0,
		RaiseError => 0,
		tdat_charset => 'UTF8',
		tdat_mode => 'TERADATA',
	}
) || die "Can't connect to $dsn: $DBI::errstr. Exiting...\n";

print STDERR "Logon to $dsn ver. " . $dbh->{tdat_version} . '(' . $dbh->{tdat_mode} . " mode) ok.\n";
my $drh = $dbh->{Driver};
print STDERR "DBD::Teradata v. $drh->{Version}\n";

die "Did not connect with CLI adapter, check your configuration."
	unless $dbh->{tdat_uses_cli} || $ENV{TDAT_DBD_NO_CLI};

print STDERR "Connected via ", ($dbh->{tdat_uses_cli} ? 'CLI' : 'pure Perl'), "\n";

dectests($dbh);

$dbh->disconnect;

print STDERR "Tests completed OK.\n";