#!/usr/bin/perl
use strict;
no warnings;
use lib qw(./t blib/lib);
use Test::More qw(no_plan);
use Data::Dumper;
use lib qw(..);
use DBConnector;
use MakeAndLoad;

use Bio::ConnectDots::ConnectorSet;
use Bio::ConnectDots::Connector;
use Bio::ConnectDots::Dot;
use Bio::ConnectDots::DotSet;
use Bio::ConnectDots::DB;

my ($HOST,$USER,$PASSWORD,$DATABASE);
my $dbinfo = Bio::ConnectDots::Config::db('test');
$HOST or $HOST=$dbinfo->{host};
$USER or $USER=$dbinfo->{user};
$PASSWORD or $PASSWORD=$dbinfo->{password};
$DATABASE or $DATABASE=$dbinfo->{dbname};

my $DBC = new DBConnector;
my $dbh = $DBC->connect($DATABASE);

SKIP: {
        skip "! Cannot test without a database connection - please adjust DB.cnf's connection parameters and \'make test\' again", 1 unless $DBC->can_connect;

print "# Creating DB connection\n";
my $db=new Bio::ConnectDots::DB(-database=>$DATABASE,-host=>$HOST,-user=>$USER,-password=>$PASSWORD);
unless ($db->is_connected) {
	is(1,1,'TEST SKIPPED: No database connection.');
	exit;
}


# test constructor
my $cs = new Bio::ConnectDots::ConnectorSet(-name=>'test_set',
												 -module=>'',
												 -db=>$db,
												 -file=>'',
												 -dotsets=>'',
												 -load_save=>'',
												 -load_chunksize=>'');
is(ref($cs), 'Bio::ConnectDots::ConnectorSet', 'check ConnectorSet constructor');

# test dotsets()
my $dotSet = new Bio::ConnectDots::DotSet(-name=>'testSet',-db=>$db);
$cs->dotsets($dotSet);
my $dotset_ret = $cs->dotsets()->[0];
#is($dotset_ret->name(), 'testSet', 'check dotsets(@DotSet) and dotsets() accessors.');



} # end SKIP 
1;