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

my $connectorsetname = 'fake_connectorset1';

# create database
my $num_fake_cs = 4;
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
# update versions column
$dbh->do("update connectorset set version='v1.0' where connectorset_id=1");
$dbh->do("update connectorset set version='v1.1' where connectorset_id=2");
$dbh->do("update connectorset set version='v1.0' where connectorset_id=3");
$dbh->do("update connectorset set version='v1.1' where connectorset_id=4");
$dbh->do("update connectorset set name='fake_connectorset0' where connectorset_id=2");
$dbh->do("update connectorset set name='fake_connectorset1' where connectorset_id=3");
$dbh->do("update connectorset set name='fake_connectorset1' where connectorset_id=4");
  
my $cd=new Bio::ConnectDots::ConnectDots(-db=>$db);


### Test connectorset queries

# query on specified connectorset version
# should make dot table from version 1.1 (old fake_connectorset2)
query  (-name=>'version_1_1_specified',
		-query_type=>'inner dot',
		-create=>1,
		-cs_version=>'v1.0',	
	    -input=>'fake_connectorset1',
	    -input_type=>'connectorset',
	    -outputs=>q(data)
  );

my $iterator = $dbh->prepare("SELECT data FROM version_1_1_specified WHERE data='2'");
$iterator->execute();
my ($answ) = $iterator->fetchrow_array();
is($answ, '2', 'Check for selection of proper version when requested.');

# check for default versioning
query  (-name=>'version_1_1_unspecified',
		-query_type=>'inner dot',
		-create=>1,
	    -input=>'fake_connectorset1',
	    -input_type=>'connectorset',
	    -outputs=>q(data)
  );

my $iterator = $dbh->prepare("SELECT data FROM version_1_1_unspecified WHERE data='3'");
$iterator->execute();
my ($answ) = $iterator->fetchrow_array();
is($answ, '3', 'Check for selection of proper version (newest) when not requested.');


### Test connectortable queries


# join fake_connectorset0 v1.1 (cs_id=2) and fake_connectorset1 v1.0 (cs_id=3) explicitly
query(
	-name       => 'versioned_ct_11_10',
	-query_type => 'outer connector',
	-create     => 1,
	-joins      => 'fake_connectorset0.data = fake_connectorset1.data',
	-cs_version => 'fake_connectorset0=v1.1, fake_connectorset1=v1.0'
);

my $iterator = $dbh->prepare("SELECT distinct connectorset_id 
							  FROM connectdot,versioned_ct_11_10 
							  WHERE fake_connectorset0=connector_id");
$iterator->execute();
my ($answ) = $iterator->fetchrow_array();
is($answ, '2', 'Check that version v1.1 was used for fake_connectorset0');

my $iterator = $dbh->prepare("SELECT distinct connectorset_id 
							  FROM connectdot,versioned_ct_11_10 
							  WHERE fake_connectorset1=connector_id");
$iterator->execute();
my ($answ) = $iterator->fetchrow_array();
is($answ, '3', 'Check that version v1.0 was used for fake_connectorset1');


# join fake_connectorset0 v1.1 (cs_id=2) and fake_connectorset1 v1.1 (cs_id=4) by default versions
query(
	-name       => 'versioned_ct_11_11',
	-query_type => 'outer connector',
	-create     => 1,
	-joins      => 'fake_connectorset0.data = fake_connectorset1.data',
);

my $iterator = $dbh->prepare("SELECT distinct connectorset_id 
							  FROM connectdot,versioned_ct_11_11 
							  WHERE fake_connectorset0=connector_id");
$iterator->execute();
my ($answ) = $iterator->fetchrow_array();
is($answ, '2', 'Check that version v1.1 was used for fake_connectorset0');

my $iterator = $dbh->prepare("SELECT distinct connectorset_id 
							  FROM connectdot,versioned_ct_11_11 
							  WHERE fake_connectorset1=connector_id");
$iterator->execute();
my ($answ) = $iterator->fetchrow_array();
is($answ, '4', 'Check that version v1.1 was used for fake_connectorset1');











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






