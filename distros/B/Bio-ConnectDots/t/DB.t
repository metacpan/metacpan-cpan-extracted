#!/usr/bin/perl
use lib qw(./t blib/lib);
use strict;
no warnings;
use Test::More qw(no_plan);
use Data::Dumper;
use DBConnector;

use Bio::ConnectDots::DB;

my $DBC = new DBConnector;
my $dbh = $DBC->connect();
my ($HOST,$USER,$PASSWORD,$DATABASE);
my $dbinfo = Bio::ConnectDots::Config::db('test');
$HOST or $HOST=$dbinfo->{host};
$USER or $USER=$dbinfo->{user};
$PASSWORD or $PASSWORD=$dbinfo->{password};
$DATABASE or $DATABASE=$dbinfo->{dbname};

SKIP: {
        skip "! Cannot test without a database connection - please adjust DB.cnf's connection parameters and \'make test\' again", 1 unless $DBC->can_connect;

# test constructor
my $db=new Bio::ConnectDots::DB(-database=>$DATABASE,
									 -host=>$HOST,
									 -user=>$USER,
									 -password=>$PASSWORD);
is (ref($db), 'Bio::ConnectDots::DB', 'check DB new() constructor');



} # end SKIP
1;
