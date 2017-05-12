use ExtUtils::MakeMaker;
use Data::Dumper;
use Getopt::Long;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $config = {
	extended => 0,
};

my $options = {};
$options->{help} = \&usage;

Getopt::Long::GetOptions($options, "help", "extended_tests", "rootpw=s", "rootuser=s", "oracle_home=s", "state_table=s", "release_table=s", "dsn=s",);

if (-e 't/config.pl')
{
	unlink 't/config.pl';
}

if ($options->{extended_tests})
{
	$config->{extended} = 1;

	eval "use DBI";
	if ($@)
	{
		die "DBI has to be installed in order to install DBIx::Sequence. ($@)\n";
	}

	$config->{dsn}           = $options->{dsn};
	$config->{root}          = $options->{rootuser} || 'root';
	$config->{rootpw}        = $options->{rootpw};
	$config->{user}		 	= $config->{root};
	$config->{userpw} 		= $config->{rootpw};
	$config->{oracle_home}   = $options->{oracle_home};
	$config->{state_table}   = $options->{state_table} || 'dbix_sequence_state';
	$config->{release_table} = $options->{release_table} || 'dbix_sequence_release';

	die "You need to specify a DSN to run extended tests" if not defined $config->{dsn};
	die "You need to specify a user to run extended tests" if not defined $config->{root};

	if ($config->{dsn} =~ /Oracle/ && !$ENV{'ORACLE_HOME'})
	{
		$ENV{'ORACLE_HOME'} = $config->{oracle_home};
	}
	my $dbh = DBI->connect(
	  $config->{dsn}, $config->{root}, $config->{rootpw}, {
		  RaiseError => 0,
		  Warn       => 0,
		  PrintError => 1,
	  }) || &creve("Could not establish a connection to DSN $dsn: $DBI::errstr");

	print "\n\nConnected.\n";
	&creve("User requested to stop.") if (ask("

###########################################################################
#			       WARNING!
###########################################################################
Extended tests require the creation of dbix_sequence_state and dbix_sequence_release tables.
These tables will be dropped (if they exists) and created for the test.

If you have any data to keep in these tables rerun 'perl Makefile.PL' with :
--state_table='state_table_name' 
--release_table='release_table_name'

Do you wish to continue ? (y|n)
  		") =~ /n|no/i);

	if ($config->{dsn} =~ /Oracle/)
	{
		$dbh->do("drop table " . $config->{state_table});
		$dbh->do("drop table " . $config->{release_table});
		print "Using ORACLE_HOME: $ENV{'ORACLE_HOME'}\n";

		$dbh->do("CREATE TABLE 
  				" . $config->{state_table} . " 
				(
					dataset varchar(50), 
					state_id NUMBER, 
					CONSTRAINT pk_dbix_sequence PRIMARY KEY (dataset, state_id)
				)
  				") || &creve("Failure in table creation: $DBI::errstr");

		print $config->{state_table} . " created.\n";
		$dbh->do("CREATE TABLE 
  					" . $config->{release_table} . " 
				(
					dataset varchar(50), 	
					released_id NUMBER, 
					CONSTRAINT pk_dbi_release PRIMARY KEY (dataset, released_id)
				)
  				") || &creve("Failure in table creation: $DBI::errstr");

		print $config->{release_table} . " created.\n";
	}
	else
	{
		$dbh->do("drop table " . $config->{state_table});
		$dbh->do("drop table " . $config->{release_table});
		$dbh->do("create table 
  					" . $config->{state_table} . " 
				(
					dataset varchar(50) NOT NULL, 
					state_id int(11) NOT NULL, PRIMARY KEY (dataset, state_id)
				)
  				") || &creve("Failure in table creation: $DBI::errstr");

		print $config->{state_table} . " created\n";
		$dbh->do("create table 
  					" . $config->{release_table} . " 
				(
					dataset varchar(50) NOT NULL, 
					released_id int(11) NOT NULL, PRIMARY KEY (dataset, released_id)
				)
  				") || &creve("Failure in table creation: $DBI::errstr");

		print $config->{release_table} . " created\n";
	}

	print "Generating t/config.pl\n";
	open(CONFIG, ">t/config.pl") || &creve("Could not write to t/config.pl");
	my $config_dump = Dumper $config;
	$config_dump =~ s/\$VAR1 \=//g;
	print CONFIG $config_dump;
	close CONFIG;
}

WriteMakefile(
  'NAME'         => 'DBIx::Sequence',
  'VERSION_FROM' => 'Sequence.pm',                               # finds $VERSION
  'AUTHOR'       => 'Benoit Beausejour <bbeausej\@pobox.com>',
  'clean'        => { 'FILES' => 'pod2html*', },
  'dist'    => { 'PREOP' => 'pod2text Sequence.pm > README; pod2html Sequence.pm README.html', },
);
exit;

sub creve
{
	my $msg = shift;
	print STDERR $msg . "\n";
	WriteMakefile(
	  'NAME'         => 'DBIx::Sequence',
	  'VERSION_FROM' => 'Sequence.pm',
	  'dist'    => { 'PREOP' => 'pod2text Sequence.pm > README; pod2html Sequence.pm README.html', },
	);
	exit;
}

sub ask
{
	my $question = shift;
	my $cache    = shift;

	print "$question \n[$cache] ";
	my $answer = <STDIN>;
	chomp $answer;
	if (!$answer) {$answer = $cache;}
	return $answer;
}

sub usage
{
	print <<"EOF";
Usage: perl Makefile.PL
--help			Prints this text
--extended_tests	Will run extended tests
--dsn			DSN to use for the tests (dbi:driver:db;host=hostname)
--rootuser		User who has CREATE, DROP, INSERT, DELETE privileges on the dsn
--rootpw		User password
--state_table		State table name for the tests (If data present)
--release_table		Release table name for the tests (If data present)
--oracle_home		If using an Oracle DSN


EOF
	exit;
}
