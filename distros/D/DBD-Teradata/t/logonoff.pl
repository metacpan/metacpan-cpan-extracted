use DBI;
use DBD::Teradata;

my $logfile;
my $usecli;
while ($ARGV[0] && (substr($ARGV[0], 0, 1) eq '-')) {
	my $op = shift @ARGV;

	$logfile = shift @ARGV,
	next
		if ($op eq '-d');

	$usecli = 1, next
		if ($op eq '-c');
}

if ($logfile) {
	unlink $logfile;
	DBI->trace(2, $logfile);
	$ENV{TDAT_DBD_DEBUG} = 2;
}

$ENV{TDAT_DBD_NO_CLI} = 1
	unless $usecli;

$dbh = DBI->connect("dbi:Teradata:$ARGV[0]", $ARGV[1], $ARGV[2],
{ PrintError => 0, RaiseError => 0, tdat_charset => 'UTF8'}) ||
die "No connection: " . $DBI::errstr;

print "Using CLI...\n"
	if $dbh->{tdat_uses_cli};

	my $sth = $dbh->prepare('sel user,date,time')
		or die $dbh->errstr;

print join(', ', $sth->{NUM_OF_PARAMS}, $sth->{NUM_OF_FIELDS}, @{$sth->{NAME}}), "\n",
join(', ', @{$sth->{TYPE}}), "\n",
join(', ', @{$sth->{PRECISION}}), "\n",
join(', ', @{$sth->{NULLABLE}}), "\n",
join(', ', @{$sth->{tdat_TYPESTR}}), "\n";

	$sth->execute || die $sth->errstr;
	$row = $sth->fetchrow_arrayref;
	print join(', ', @$row), "\n";

$dbh->disconnect;
