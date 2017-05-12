#!/usr/local/bin/perl
# Tests removal of connectorset's effect on tables made with that obsolete connectorset
# Author: David Burdick 08/10/2004

use strict;
use lib qw(./t blib/lib);
use Bio::ConnectDots::ConnectDots;
use Bio::ConnectDots::DB;
use MakeAndLoad;
use DBConnector;
use Class::AutoClass::Args;
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

### Connectortables
# build connectortable then delete a connectorset
query  (-name=>'obsolete_ct',
		-query_type=>'outer connector',
		-create=>1,
		-joins=>q(fake_connectorset0.data = fake_connectorset1.data, 
				  fake_connectorset1.data = fake_connectorset2.data)
  );

system "perl ../lib/Bio/ConnectDots/scripts/unload.pl --database $DATABASE --connectorset fake_connectorset2 --removedots 1";

is(1,1,'Completed Instantiation Test');


### Dottables

#my $iterator = $dbh->prepare("");
#$iterator->execute();
#while (my @cols = $iterator->fetchrow_array()) {
#		
#}



sub query {
  my $args=new Class::AutoClass::Args(@_);
  print $args->name,"\t",`date`;
  $cd->query(@_);
}






