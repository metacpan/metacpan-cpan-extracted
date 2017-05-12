#!/usr/bin/perl -w
#
# Tests for Data::Toolkit::Connector::DBI

use strict;

use lib '../lib';

use Carp;
use Test::Simple tests => 14;

use Data::Toolkit::Connector;
use Data::Toolkit::Connector::DBI;
use Data::Toolkit::Entry;
use Data::Toolkit::Map;
use Data::Dumper;
use DBI;
# Not explicitly needed here, but this makes the point that we need the module:
use DBD::SQLite;
#

my $dbFile = "testdbfile.sqlite";

# Get to the right directory
chdir 'tests' if -d 'tests';

my $verbose = 0;
ok (Data::Toolkit::Connector::DBI->debug($verbose) == $verbose, "Setting Connector debug level to $verbose");

# Remove the old DB file if it exists
unlink $dbFile;

my $db = Data::Toolkit::Connector::DBI->new();
ok (($db and $db->isa( "Data::Toolkit::Connector::DBI" )), "Create new Data::Toolkit::Connector::DBI object");

# Wind up the database module
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbFile")
	or die "Cannot connect: " . $DBI::errstr;

# Create a table
$dbh->do( "CREATE TABLE people ( joinkey INTEGER, sn VARCHAR, initials VARCHAR )" )
	or die "Cannot create people table: " . $DBI::errstr;

# Load some data
$dbh->do( "INSERT INTO people (joinkey, sn, initials) values(1,'Smith','J')" ) or die "Cannot insert data into people table" . $DBI::errstr;
$dbh->do( "INSERT INTO people (joinkey, sn, initials) values(2,'Jones','I')" ) or die "Cannot insert data into people table" . $DBI::errstr;
$dbh->do( "INSERT INTO people (joinkey, sn, initials) values(3,'Brown','A')" ) or die "Cannot insert data into people table" . $DBI::errstr;

ok ($db->server( $dbh ), "Assign DBI server connection");

#
# Test the search function
#
my $entry;
$db->filterspec( "SELECT joinkey,sn FROM people WHERE joinkey = 42" );
$db->search() or die "Search operation failed: cannot continue";
$entry = $db->next();
ok (!$entry, "There is no joinkey 42");

$db->filterspec( "SELECT joinkey,sn FROM people WHERE joinkey = 3" );
$db->search() or die "Search operation failed: cannot continue";
$entry = $db->next();
ok (($entry and $entry->get('sn')->[0] eq 'Brown'), "Selecting on joinkey 3");
# print "GOT ", $entry->dump(), "\n";

#
# Test search using data from an entry
#

my $e2 = Data::Toolkit::Entry->new();
$e2->set('_dn', ['cn=test-1,dc=example,dc=org']);
$e2->set('sn',['Beeblebrox']);

print "####\n", $entry->dump(), "\n####\n" if $verbose;

$db->filterspec( "SELECT joinkey,sn FROM people WHERE sn = %sn%" );
$db->search($e2) or die "Search operation failed: cannot continue";
$entry = $db->next();
ok (!$entry, "There is no Beeblebrox here");

$e2->set('sn',['Jones']);
$db->search($e2) or die "Search operation failed: cannot continue";
$entry = $db->next();
ok (($entry and ($entry->get("joinkey")->[0] eq 2)), "Found Jones");

#
# Try merging rows into a single entry
#
$db->filterspec( "SELECT joinkey,sn FROM people WHERE joinkey < 3" );
$db->search() or die "Search operation failed: cannot continue";
$entry = $db->allrows();
ok (($entry and (join ':',$entry->get('sn')) eq 'Jones:Smith'), "Selecting all rows with joinkey < 3");
print "GOT ", $entry->dump(), "\n" if $verbose;

#
# Build an entry to be added
#
my $e3 = Data::Toolkit::Entry->new();
$e3->set('key',[101]);
$e3->set('sn',['Dent']);
$e3->set('initials',['A']);
print "e3: ", $e3->dump(), "\n" if $verbose;

$db->addspec( "INSERT INTO people (joinkey,sn,initials) VALUES (%key%, %sn%, %initials%)" );
ok (($db->add($e3) == 1), "Add one row to the database");

# Check that it really got there
$db->filterspec( "SELECT joinkey,initials,sn FROM people WHERE joinkey = 101" );
$db->search() or die "Search operation failed: cannot continue";
$entry = $db->next();
ok (($entry and ($entry->get('sn')->[0] eq 'Dent')), "Get the entry that we just added");

#
# Modify that entry and update
#
$e3->set('sn',['Desiato']);
$e3->set('initials',['H']);
#
print "e3: ", $e3->dump(), "\n" if $verbose;
$db->updatespec( "UPDATE people set sn = %sn%, initials = %initials% WHERE joinkey = %key%" );
$db->update($e3);

# Check that it really got there (using the same filterspec as before)
$db->search() or die "Search operation failed: cannot continue";
$entry = $db->next();
print "GOT ", $entry->dump(), "\n" if $verbose;
ok (($entry and ($entry->get('sn')->[0] eq 'Desiato')), "Get the entry that we just updated");

#
# Build a delete spec to get rid of an entry
#
$db->deletespec( "DELETE FROM people where joinkey = %key%" );
ok (($db->delete($e3) == 1), "Deleting entry from DB");

#
# Check that we still have some of the original entries
# Try out percent-escaping while we are about it
#
$db->filterspec( "SELECT joinkey,sn FROM people WHERE sn LIKE 'S%%'" );
$db->search() or die "Search operation failed: cannot continue";
$entry = $db->next();
ok (($entry and $entry->get('sn')->[0] eq 'Smith'), "Selecting on sn LIKE 'S%'");
# print "GOT ", $entry->dump(), "\n";

#
# Getting placehoders to work with LIKE could be a challenge...
#
$e3->set('firstletter', ['J']);
# $db->filterspec( "SELECT joinkey,sn FROM people WHERE sn LIKE CONCAT(%firstletter%, '%%')" );
$db->filterspec( "SELECT joinkey,sn FROM people WHERE sn LIKE (%firstletter% || '%%')" );
$db->search($e3) or die "Search operation failed: cannot continue";
$entry = $db->next();
ok (($entry and $entry->get('sn')->[0] eq 'Jones'), "Selecting on sn LIKE with placeholder and %");
# print "GOT ", $entry->dump(), "\n";

