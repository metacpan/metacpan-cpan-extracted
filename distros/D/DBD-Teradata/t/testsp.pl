BEGIN {
	push @INC, './t';
	$ENV{TDAT_DBD_NO_CLI} = 1;
	$ENV{TDAT_DBD_DEBUG} = 1;
}

use DBI;
use DBD::Teradata;
use TdTestProcs qw(sptests);

DBI->trace(2, 'sptest.log');

my $dbh = DBI->connect("dbi:Teradata:$ARGV[0]", $ARGV[1], $ARGV[2]) || die $DBI::errstr;

sptests($dbh);

$dbh->disconnect();
