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

	query(
		-name       => 'sets3',
		-query_type => 'outer connector',
		-create     => 1,
		-joins      => "
			fake_connectorset0.data = fake_connectorset1.data AND
			fake_connectorset1.data = fake_connectorset2.data
		",
	);


query ( -name=>'dotInner',
	-query_type=>'inner dot',
	-create=>1,
	-input=> 'sets3',
	-input_type => 'connectortable',        
	-outputs=>q(fake_connectorset0.data AS data0, fake_connectorset1.data AS data1, fake_connectorset2.data AS data2) 
        );
my $iterator = $dbh->prepare("SELECT * FROM dotInner");
$iterator->execute();
while (my @cols = $iterator->fetchrow_array()) {
	grep is($_, '0_1_2', 'checking output'), @cols; #each should be 0_1_2
}

done();
sub pdate {print @_,' ',`date`;}
