#!/usr/local/bin/perl
# Tests the ability to export DotTables to properly formatted XML.
# Author: David Burdick 08/10/2004

use lib qw(./t blib/lib);
use strict;
use Bio::ConnectDots::ConnectDots;
use Bio::ConnectDots::DB;
use MakeAndLoad;
use DBConnector;
use Class::AutoClass::Args;
use Test::More;
use Test::XML::XPath qw(no_plan);
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

# insert extra stuff
$dbh->do("INSERT INTO connectdot VALUES(6,2,8,1,'<w00t>')");
$dbh->do("INSERT INTO connectdot VALUES(12,3,9,1,'n00b')");
  
my $cd=new Bio::ConnectDots::ConnectDots(-db=>$db);

# connector table
query  (-name=>'xml_ct',
		-query_type=>'outer connector',
		-create=>1,
		-joins=>q(fake_connectorset0.data = fake_connectorset1.data, 
				  fake_connectorset1.data = fake_connectorset2.data)
  );

my $xmlfilename = '/tmp/CTD_output_xml.xml';
# dot table
query  (-name=>'xml_dot',
		-query_type	=>'outer dot',
		-create		=>1,
	    -input		=>'xml_ct',
	    -input_type	=>'connectortable',
	    -outputs	=>q(fake_connectorset0.data AS fc0,fake_connectorset1.data as fc1,
	    				fake_connectorset2.data as fc2),
	    -xml_root	=>'fc0',
	    -xml_file	=>$xmlfilename
  );


### retrieve xml, strip dtd
open (XML, $xmlfilename);
my $xml;
my $skipDTD=0;
while(<XML>) {
	if(!$skipDTD) {
		$skipDTD = 1;	
	} else {
		$xml .= $_;	
	}
}

print "$xml\n";

### Test XML output
like_xpath($xml,'/DotTable/fc0[@id="0"]',"Test that each id is present");
like_xpath($xml,'/DotTable/fc0[@id="0_1"]',"Test that each id is present");
like_xpath($xml,'/DotTable/fc0[@id="0_1_2"]',"Test that each id is present");
like_xpath($xml,'/DotTable/fc0[@id="0_2"]',"Test that each id is present");

is_xpath($xml,'/DotTable/fc0[@id="0_1"]/fc1','<w00t>0_1','check multiple row collapse');
is_xpath($xml,'/DotTable/fc0[@id="0_1_2"]/fc1','0_1_2','check multiple row collapse');
is_xpath($xml,'/DotTable/fc0[@id="0_1_2"]/fc2','0_1_2n00b','check multiple row collapse');

close(XML);




sub query {
  my $args=new Class::AutoClass::Args(@_);
  print $args->name,"\t",`date`;
  $cd->query(@_);
}
