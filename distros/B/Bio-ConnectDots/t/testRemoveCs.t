use lib qw(./t blib/lib);
use strict;
use Bio::ConnectDots::ConnectDots;
use Bio::ConnectDots::DB;
use MakeAndLoad;
use DBConnector;
use Test::More qw(no_plan);

use Carp;
use Getopt::Long;
use Text::Abbrev;



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
Options
-------
   --help               Print this message
   --verbose            (for testing)
   -X or --echo         Echo command line (for testing and use in scripts)
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


my($HELP,$VERBOSE,$ECHO_CMD,$DATABASE,$HOST,$USER,$PASSWORD,$LOADDIR,$LOADSAVE,$CREATE,$JUST_CREATE);

### setup database variables
my $dbinfo = Bio::ConnectDots::Config::db('test');
$HOST or $HOST=$dbinfo->{host};
$USER or $USER=$dbinfo->{user};
$PASSWORD or $PASSWORD=$dbinfo->{password};
$DATABASE or $DATABASE=$dbinfo->{dbname};

my $connectorsetname = 'fake_connectorset1';

# create database
my $num_fake_cs = 3;
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
$mal->create_db($num_fake_cs,$dbinfo);
  
my $cd=new Bio::ConnectDots::ConnectDots(-db=>$db);

# add in extra labels and dotsets
$dbh->do("insert into label values(2,'stay')");
$dbh->do("insert into label values(3,'remove')");
$dbh->do("insert into dotset values(2,'stayset')");
$dbh->do("insert into dotset values(3,'removeset')");

$dbh->do("insert into connectdotset values(4,1,2,2)"); #stay
$dbh->do("insert into connectdotset values(4,2,2,2)"); #stay
$dbh->do("insert into connectdotset values(5,2,3,3)"); #remove

# add version attributes
$dbh->do("update connectorset set version='v1.0' where connectorset_id=3"); #stay 
$dbh->do("update connectorset set version='v1.1' where connectorset_id=2"); #remove
$dbh->do("update connectorset set name='fake_connectorset1' where connectorset_id=3"); #stay

# remove connectorset 2, test default removal of newest version
system "perl blib/lib/Bio/ConnectDots/scripts/unload.pl --database $DATABASE --connectorset $connectorsetname  --removedots 1";

# check connectorset removal
my $gone = 1;
my $iterator = $dbh->prepare("SELECT name,version FROM connectorset");
$iterator->execute();
while (my ($name,$version) = $iterator->fetchrow_array()) {
	$gone = 0 if ($name eq $connectorsetname) && ($version eq 'v1.1');
}
is($gone, 1, "Check for removal of $connectorsetname version v1.1 entry");

# check that label 'remove' is gone and 'stay' is retained
my $removegone=1;
my $staypresent=0;
my $iterator = $dbh->prepare("SELECT label FROM label");
$iterator->execute();
while (my @cols = $iterator->fetchrow_array()) {
	$removegone = 0 if $cols[0] eq 'remove';
	$staypresent = 1 if $cols[0] eq 'stay';
}
is($removegone, 1, "Checking removal of labels");
is($staypresent, 1, "Checking retention of labels");

# check that dotset 'removeset' is gone and 'stayset' is retained
$removegone=1;
$staypresent=0;
my $iterator = $dbh->prepare("SELECT name FROM dotset");
$iterator->execute();
while (my @cols = $iterator->fetchrow_array()) {
	$removegone = 0 if $cols[0] eq 'removeset';
	$staypresent = 1 if $cols[0] eq 'stayset';
}
is($removegone, 1, "Checking removal of dotsets");
is($staypresent, 1, "Checking retention of dotsets");

# check that rows were removed from connectdot
my $iterator = $dbh->prepare("SELECT count(*) FROM connectdot WHERE connectorset_id=2");
$iterator->execute();
my @cols = $iterator->fetchrow_array();
is($cols[0], 0, "Checking deleted entries from connectdot");

# check that dots were removed from dot
my $cs1_id=0;
my $iterator = $dbh->prepare("SELECT id FROM dot");
$iterator->execute();
while (my @cols = $iterator->fetchrow_array()) {
	$cs1_id = 1 if $cols[0] eq '1';
}
is($cs1_id, 0, "Checking that $connectorsetname dots are removed");

# check direct version removal
# remove connectorset 2, test default removal of newest version
system "perl blib/lib/Bio/ConnectDots/scripts/unload.pl  --database $DATABASE --connectorset $connectorsetname --version v1.0 --removedots 1";

# check connectorset removal
my $gone = 1;
my $iterator = $dbh->prepare("SELECT name,version FROM connectorset");
$iterator->execute();
while (my ($name,$version) = $iterator->fetchrow_array()) {
	$gone = 0 if ($name eq $connectorsetname) && ($version eq 'v1.0');
}
is($gone, 1, "Check for removal of $connectorsetname version v1.0 entry");


















