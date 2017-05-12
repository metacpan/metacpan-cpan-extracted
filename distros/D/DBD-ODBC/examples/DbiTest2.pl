use strict;
# $Id$

use warnings;

use DBI;

use Data::Dumper;
$Data::Dumper::Maxdepth = 4;

use constant LONG_READ_LEN => 8000;

my %options = (
	DbSrcServer       => '(local)',
	DbSrcDatabase     => 'Helpdesk2',
	DbSrcLoginName    => 'sa',
	DbSrcPassword     => '',
);

my @dbhPool;

##########################################
### Functions
##########################################

sub newDbh()
{my $dbh;
	if(defined($options{DbSrcServer}) && defined($options{DbSrcLoginName}) && defined($options{DbSrcDatabase}))
	{	my $dsn = "DRIVER={SQL Server};SERVER=$options{DbSrcServer};DATABASE=$options{DbSrcDatabase};NETWORK=dbmssocn;UID=$options{DbSrcLoginName};PWD=$options{DbSrcPassword}";
#		print "DSN: $dsn\n\n";

		$dbh = DBI->connect("DBI:ODBC:$dsn") || die "DBI connect failed: $DBI::errstr\n";
		$dbh->{AutoCommit} = 0;	# enable transactions, if possible
		$dbh->{RaiseError} = 0;
		$dbh->{PrintError} = 1;	# use RaiseError instead
		$dbh->{ShowErrorStatement} = 1;

		push @dbhPool, $dbh;
		return($dbh);
	}
}


sub test($)
{	my ($outputTempate) = @_;

	my $dbh = newDbh();
	my $sth = $dbh->prepare('select ID from (select 1 as ID union select 2 as ID union select 3 as ID) tmp order by ID');

	$sth->execute();

#	print '$sth->{Active}: ', $sth->{Active}, "\n";
	do
	{	for(my $rowRef = undef; $rowRef = $sth->fetchrow_hashref('NAME'); )
		{	#print '%$rowRef ', Dumper(\%$rowRef), "\n";
			innerTest($outputTempate);
		}
	} while($sth->{odbc_more_results});
}



my $innerTestSth;

sub innerTest($)
{	my ($outputTempate) = @_;

	my %outputData;
	my $queryInputParameter1 = 2222;
	my $queryOutputParameter = $outputTempate;

	my $sth;

	if(!defined $innerTestSth)
	{	my $dbh = newDbh();
		$innerTestSth = $dbh->prepare('{? = call testPrc(?) }');
	}
	$sth = $innerTestSth;

	$sth->bind_param_inout(1, \$queryOutputParameter, 30, { TYPE => DBI::SQL_INTEGER });
	$sth->bind_param(2, $queryInputParameter1, { TYPE => DBI::SQL_INTEGER });

#	$sth->trace(1);#, 'DbiTest.txt');
	$sth->execute();

	print '$sth->{Active}: ', $sth->{Active}, "\n";
	do
	{	for(my $rowRef = undef; $rowRef = $sth->fetchrow_hashref('NAME'); )
		{	print '%$rowRef2 ', Dumper(\%$rowRef), "\n";
		}
	} while($sth->{odbc_more_results});

	print '$queryOutputParameter: \'', $queryOutputParameter,
		'\' expected: (', $queryInputParameter1 + 1, ")\n\n";
}



##########################################
### Test
##########################################

#test(0);
#test(10);
#test(100);
#test('     ');

test(10);

##########################################
### Cleanup...
##########################################

foreach my $dbh (@dbhPool)
{	$dbh->rollback();
	$dbh->disconnect();
}




