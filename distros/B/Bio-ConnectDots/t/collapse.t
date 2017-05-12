#!/usr/local/bin/perl
# Tests the ability to have multiple versions of the same connectorset concurrently loaded
# Author: David Burdick 08/10/2004

use strict;
use lib qw(./t blib/lib);
use Bio::ConnectDots::ConnectDots;
use Bio::ConnectDots::DB;
use MakeAndLoad;
use DBConnector;
use Class::AutoClass::Args;
use Test::More qw(no_plan);

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

# insert extra values
$dbh->do("INSERT INTO label VALUES(2,'extra')");
$dbh->do("INSERT INTO connectdotset VALUES(4,1,1,2)");
$dbh->do("INSERT INTO connectdot VALUES(1,1,8,2,'w00t')");
$dbh->do("INSERT INTO connectdot VALUES(1,1,9,2,'')");
$dbh->do("INSERT INTO connectdot VALUES(1,1,10,2,'n00b')");
  
my $cd=new Bio::ConnectDots::ConnectDots(-db=>$db);


### Test collapse
query  (-name=>'collapsetest',
		-query_type=>'outer dot',
		-create=>1,
		-collapse=>'data',
		-collapse_seperator=>'//', 
	    -input=>'fake_connectorset0',
	    -input_type=>'connectorset',
	    -outputs=>q(data,extra)
  );




my $iterator = $dbh->prepare("SELECT data,extra FROM collapsetest");
$iterator->execute();
while (my @cols = $iterator->fetchrow_array()) {
	if($cols[0] eq '0') {
		is($cols[1], 'w00t//n00b', "check proper collapse on id 0");
	}	elsif ($cols[0] eq '0_1' || $cols[0] eq '0_1_2' || $cols[0] eq '0_2') {
		is($cols[1], '', "verifying blank row on $cols[0]");
	}	else {
		is(0, 1, "Unexpected row: @cols");
	}	
}



sub query {
  my $args=new Class::AutoClass::Args(@_);
  print $args->name,"\t",`date`;
  $cd->query(@_);
}






