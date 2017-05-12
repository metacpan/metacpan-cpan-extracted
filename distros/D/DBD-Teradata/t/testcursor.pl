BEGIN {
	push @INC, './t';
}

use DBI;
use DBD::Teradata;
use TdTestCursors qw(init_for_cursors updatable_cursor persistent_cursor rewind_cursor);

use strict;
use warnings;

$| = 1;

my $load;

while ($ARGV[0] && (substr($ARGV[0], 0, 1) eq '-')) {
	my $op = shift @ARGV;

	$load = 1,
	next
		if ($op eq '-l');

	$ENV{TDAT_DBD_NO_CLI} = 1,
	next
		if ($op eq '-c');

	$ENV{TDAT_DBD_DEBUG} = 1,
	DBI->trace(2, shift @ARGV),
	next
		if ($op eq '-d');
}


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
#
#	force dateform to integer
#
$dbh->do('set session dateform=integerdate');

init_for_cursors($dbh, 1000)
	if $load;

updatable_cursor($dbh, $dsn, $userid, $passwd);

persistent_cursor($dbh);
rewind_cursor($dbh);

$dbh->disconnect;

print STDERR "Tests completed OK.\n";

sub cleanup {
	my $dbh = shift;

$dbh->do( 'DROP TABLE alltypetst');
die $dbh->errstr
	if $dbh->err && ($dbh->err != 3807);

my $ctsth = $dbh->do( 'CREATE TABLE alltypetst, NO FALLBACK (
col1 integer,
col2 smallint,
col3 byteint,
col4 char(20) character set unicode,
col5 varchar(100) character set unicode,
col6 float,
col7 decimal(2,1),
col8 decimal(4,2),
col9 decimal(8,4),
col10 decimal(14,5),
col11 date,
col12 time,
col13 timestamp(0))
unique primary index(col1);'
) || die ($dbh->errstr . "\n");

}