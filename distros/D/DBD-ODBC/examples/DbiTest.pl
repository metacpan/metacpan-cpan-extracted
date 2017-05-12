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


sub test($;$)
{	my ($outputTempate, $recurse) = @_;
	
	my $dbh = newDbh();
	my $queryInputParameter1 = 2222;
	my $queryOutputParameter = $outputTempate;
	
	my $sth = $dbh->prepare('{? = call testPrc(?) }');
	$sth->bind_param_inout(1, \$queryOutputParameter, 30, { TYPE => DBI::SQL_INTEGER });
	$sth->bind_param(2, $queryInputParameter1, { TYPE => DBI::SQL_INTEGER });
					
#	$sth->trace(1);#, 'DbiTest.txt');
	$sth->execute();

	print '$sth->{Active}: ', $sth->{Active}, "\n";
	do
	{	for(my $rowRef; $rowRef = $sth->fetchrow_hashref('NAME'); )
		{	my %outputData = %$rowRef;
			
			print 'outputData ', Dumper(\%outputData), "\n";
			if($recurse > 0)
			{	test($dbh, --$recurse);
			}
		}
	} while($sth->{odbc_more_results});

	print '$queryOutputParameter: \'', $queryOutputParameter, 
		'\' expected: (', $queryInputParameter1 + 1, ")\n\n";
}




##########################################
### Test
##########################################

test(0,       0);
test(10,      0);
test(100,     0);
test('     ', 0);

test(0, 1);	#recusion

##########################################
### Cleanup...
##########################################

foreach my $dbh (@dbhPool)
{	$dbh->rollback();
	$dbh->disconnect();
}


			
		
