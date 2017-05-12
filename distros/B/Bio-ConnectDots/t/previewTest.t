use lib qw(./t blib/lib);
use Carp;
use Getopt::Long;
use Bio::ConnectDots::ConnectDots;
use Bio::ConnectDots::DB;
use Class::AutoClass::Args;
use strict;
use Test::More qw(no_plan);
use MakeAndLoad;
use DBConnector;


my $cmd_line="$0 @ARGV";
my($HELP,$VERBOSE,$ECHO_CMD,$DATABASE,$HOST,$USER,$PASSWORD,$LOADDIR,$LOADSAVE,$CREATE,$JUST_CREATE);

GetOptions ('help' => \$HELP,
 	    'verbose' => \$VERBOSE,
	    'X|echo' => \$ECHO_CMD,
	    'database=s'=>\$DATABASE,
            'db=s'=>\$DATABASE,
            'host=s'=>\$HOST,
            'user=s'=>\$USER,
            'password=s'=>\$PASSWORD,
	    'loaddir=s'=>\$LOADDIR,
	    'loadsave=s'=>\$LOADSAVE,
	    'create'=>\$CREATE,
	    'just_create'=>\$JUST_CREATE,
	   ) and !$HELP or die <<USAGE;
Usage: $0 [options] 

Benchmark connect-the-dots queries

Options
-------
   --help		Print this message
   --verbose		(for testing)
   -X or --echo		Echo command line (for testing and use in scripts)
  --database            Postgres database (default: --user)
  --db                  Synonym for --database
  --host                Postgres database (default: socks)
  --user                Postgres user (default: ngoodman)
  --password            Postgres password (default: undef)
  --loaddir             Directory for load files (default: /tmp/user_name)
  --loadsave            Specifies whether to save load files
                        Options: 'none', 'last', 'all'. Default: 'all'
  --create              Create table base_c needed for DotTable queries
  --just_create         Create base_c and exit

Options may be abbreviated.  Values are case insenstive.

USAGE
;
print "$cmd_line\n" if $ECHO_CMD;
### setup database variables
my $dbinfo = Bio::ConnectDots::Config::db('test');
$HOST or $HOST=$dbinfo->{host};
$USER or $USER=$dbinfo->{user};
$PASSWORD or $PASSWORD=$dbinfo->{password};
$DATABASE or $DATABASE=$dbinfo->{dbname};

# create database
my $dbC = new DBConnector; 
$dbC->connect($DATABASE);

my $db=new Bio::ConnectDots::DB(-database=>$DATABASE,-host=>$HOST,-user=>$USER,-password=>$PASSWORD);
unless ($db->is_connected) {
	is(1,1,'TEST SKIPPED: No database connection.');
	exit;
}

my $dbh = $db->dbh;  
# add fake connector sets
my $mal = new MakeAndLoad;
$mal->create_db(3,$dbinfo);
  
my $cd=new Bio::ConnectDots::ConnectDots(-db=>$db);

$|=1;
sub query {
  my $args=new Class::AutoClass::Args(@_);
  print $args->name,"\t",`date`;
  $cd->query(@_);
}
sub done {print "done\t",`date`; exit;}

# Inner Connectortable
query(
	-name       => 'sets3_innerc',
	-query_type => 'inner connector',
	-create     => 1,
	-preview		=> 1,
	-cs_aliases => "fake_connectorset0 AS f0, fake_connectorset1 AS f1, fake_connectorset2 AS f2",
	-joins      => "f0.data = f1.data AND
									f1.data = f2.data",
);

# Outer Connectortable
query(
	-name       => 'sets3_outerc',
	-query_type => 'outer connector',
	-create     => 1,
	-preview		=> 1,
	-cs_aliases => "fake_connectorset0 AS f0, fake_connectorset1 AS f1, fake_connectorset2 AS f2",
	-joins      => "f0.data = f1.data AND
									f1.data = f2.data",
);

# Inner DotTable from Connectorset
query(
	-name       => 'previewDotInnerCs',
	-query_type => 'inner dot',
	-create     => 1,
	-preview		=> 1,
	-input      => 'fake_connectorset0',
	-input_type => 'connectorset',
	-outputs    => q(data)
);

# Outer DotTable from ConnectorSet
query(
	-name       => 'previewDotOuterCs',
	-query_type => 'outer dot',
	-create     => 1,
	-preview		=> 1,
	-input      => 'fake_connectorset0',
	-input_type => 'connectorset',
	-outputs    => q(data)
);

# Inner DotTable from ConnectorTable
query(
	-name       => 'previewDotInnerCt',
	-query_type => 'inner dot',
	-create     => 1,
	-preview		=> 1,
	-input      => 'sets3_outerc',
	-input_type => 'connectortable',
	-outputs    => q(f0.data)
);

# Outer DotTable from ConnectorTable
query(
	-name       => 'previewDotOuterCt',
	-query_type => 'outer dot',
	-create     => 1,
	-preview		=> 1,
	-input      => 'sets3_outerc',
	-input_type => 'connectortable',
	-outputs    => q(f0.data)
);

is(1,1,'instantiation test');

done();
sub pdate {print @_,' ',`date`;}
