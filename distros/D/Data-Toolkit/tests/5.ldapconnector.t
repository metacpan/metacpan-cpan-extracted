#!/usr/bin/perl -w
#
# Tests for Data::Toolkit::Connector::LDAP
#
# These require an LDAP server

use strict;

use lib '../lib';

use Carp;
use Test::More tests => 51;

use Data::Toolkit::Connector;
use Data::Toolkit::Connector::LDAP;
use Data::Toolkit::Entry;
use Data::Toolkit::Map;
use Data::Dumper;
use Net::LDAP;

# Port number for LDAP server
my $ldapURI = 'ldap://localhost:19389';
# DN and password for LDAP server
my $adminDN = 'cn=root,dc=example,dc=org';
my $adminPW = 'secret';

# Make sure we always stop the LDAP server
END {
	system './stop-slapd';
}

# Get to the right directory
chdir 'tests' if -d 'tests';

my $verbose = 0;
ok (Data::Toolkit::Connector::LDAP->debug($verbose) == $verbose, "Setting Connector debug level to $verbose");


# Basic test without LDAP server
{
	my $conn = Data::Toolkit::Connector::LDAP->new();
	ok (($conn and $conn->isa( "Data::Toolkit::Connector::LDAP" )), "Create new Data::Toolkit::Connector::LDAP object");
	my $ent = Net::LDAP::Entry->new();
	ok (($ent and $ent->isa( "Net::LDAP::Entry" )), "Create new Net::LDAP::Entry object");
	$ent->add( 'myattr' => 'myval' );

	# Make sure that when we set a Net::LDAP::Entry as current it gets converted to Data::Toolkit::Entry
	my $ent2 = $conn->current( $ent );
	ok (($ent2 and $ent2->isa( "Data::Toolkit::Entry" )), "Current entry was converted to the right type");
	# print Dumper( $ent2 ), "\n";
	my $val = $ent2->get( 'myattr' );
	$val = $val->[0] if $val;
	ok (($val and ($val eq 'myval')), "Retrieve value from entry");

	# If we tell the connector to update the entry to itself it should return OK status
	# without ever using LDAP
	# my $msg = $conn->update( $ent2 );
	# ok (($msg and ($msg->is_error() == 0)), "Null update return status");
}


# From here on we need the OpenLDAP server
#
SKIP: {
	skip ('No OpenLDAP server found on this system', 46)
		unless (
			-f '/usr/local/etc/openldap/schema/core.schema' or
			-f '/usr/local/etc/schema/core.schema' or
			-f '/usr/local/openldap/etc/schema/core.schema' or
			-f '/etc/openldap/schema/core.schema'
		);

	# Clean out LDAP server and restart it
	ok ( ((system './clear-slapd') == 0), "Clear LDAP server");
	skip( 'Cannot start OpenLDAP server', 45)
		unless ((system './start-slapd') == 0);


	my $conn = Data::Toolkit::Connector::LDAP->new();
	ok (($conn and $conn->isa( "Data::Toolkit::Connector::LDAP" )), "Create new Data::Toolkit::Connector::LDAP object");

	#
	# Prepare environment for LDAP
	#
	my $ldap = Net::LDAP->new( $ldapURI );
	die "Cannot connect to LDAP server at $ldapURI" if !$ldap;
	my $msg;
	$msg = $ldap->bind($adminDN, password => $adminPW);
	die "Cannot bind to LDAP with admin DN: " . $msg->error if $msg->is_error;

	ok ($conn->server( $ldap ), "Assign LDAP server connection");

	my $entry = Data::Toolkit::Entry->new();
	$entry->set('_dn', ['cn=test-1,dc=example,dc=org']);
	$entry->set('objectClass', ['inetOrgPerson','organizationalPerson','person']);
	$entry->set('cn',['test-1','Test Entry One','Zaphod']);
	$entry->set('sn',['Beeblebrox']);

	print "####\n", $entry->dump(), "\n####\n" if $verbose;

	# Add entry to LDAP
	$msg = $conn->add($entry);
	ok (($msg and !$msg->is_error), "Add entry to LDAP");
	if ($msg and $msg->is_error) {
		print "Error was: ", $msg->error, "\n";
	}

	# Add another similar one
	$entry->set('_dn', ['cn=test-2,dc=example,dc=org']);
	$entry->set('cn',['test-2','Test Entry Two','Marvin']);
	$entry->set('sn',['Android']);
	$msg = $conn->add($entry);
	ok (($msg and !$msg->is_error), "Add entry to LDAP");
	if ($msg and $msg->is_error) {
		print "Error was: ", $msg->error, "\n";
	}

	#
	# Test the search function
	#
	my $search = Data::Toolkit::Connector::LDAP->new();
	ok (($search and $search->isa( "Data::Toolkit::Connector::LDAP" )), "Create search object");
	ok ($search->server( $ldap ), "Assign LDAP server connection to search object");
	ok (!defined($search->searchparams()), "No search params defined yet");
	ok ($search->searchparams( { base => 'dc=example,dc=org', filter => '(cn=Zaphod)', scope => 'sub' } ),
		"Define search parameters");
	$msg = $search->search();
	ok (($msg->count() == 1), "LDAP search with params only should find one entry");
	ok (($msg->entry(0)->get_value('sn') eq 'Beeblebrox'), "Entry has correct sn attribute");

	# New search params with no filter spec
	$search->searchparams( { base => 'dc=example,dc=org', scope => 'sub' } );
	# Supply the filter spec separately
	ok ($search->filterspec( '(cn=Marvin)' ), "Setting filter spec");
	# Run the same search again
	$msg = $search->search();
	ok (($msg->count() == 1), "LDAP search with filterspec should find one entry");
	ok (($msg->entry(0)->get_value('sn') eq 'Android'), "Entry has correct sn attribute");

	# Build an entry with some attributes to be matched
	my $person = Data::Toolkit::Entry->new();
	$person->set( 'given', [ 'zaphod' ] );
	$person->set( 'mail', [ 'zb@plural-z.alpha' ] );
	$person->set( 'phone', [ '+00', '+999999999' ] );

	# New search spec
	$search->filterspec( '(&(cn=%given%)(objectclass=person))' );

	# Try the search using the entry to supply data
	$msg = $search->search( $person );
	ok (($msg->count() == 1), "LDAP search using supplied entry should find one entry");
	ok (($msg->entry(0)->get_value('sn') eq 'Beeblebrox'), "Entry has correct sn attribute");

	#
	# Use the next method to extract data
	#
	my $found = $search->next();
	ok (($found and ($found->get('sn')->[0] eq 'Beeblebrox')), "Using 'next' method to extract entry");
	# And again
	$found = $search->next();
	ok (!$found, "No more data to be got with 'next'");


	# Build a map
	my $map = Data::Toolkit::Map->new();
	ok (($map and $map->isa( "Data::Toolkit::Map" )), "Create new Data::Toolkit::Map object");
	$map->set('lastname','sn');
	$map->set('_dn','_dn');
	# Prepare a new search
	$search->filterspec( '(cn=Test*)' );
	$msg = $search->search();
	ok (($msg->count() == 2), "Search found two entries");
	my $current = $search->current();
	ok (!$current, "current() method must return false before next() called");
	#
	# Get the data through a map, testing next and current methods
	#
	$found = $search->next($map);
	# print "ONE: ", $found->dump(), "\n";
	ok (($found and $found->get('lastname')->[0] =~ /Beeblebrox|Android/), "Mapping OK for first entry");
	my $saveDN = $found->get('_dn')->[0];
	ok (($saveDN and $saveDN =~ /,dc=example,dc=org$/), "Entry contains reasonable DN");
	$current = $search->current();
	ok (($current and ($current->get('_dn')->[0] eq $saveDN)), "'current' method returns same DN");
	#
	$found = $search->next($map);
	ok (($found and $found->get('lastname')->[0] =~ /Beeblebrox|Android/), "Mapping OK for second entry");
	# print "TWO: ", $found->dump(), "\n";
	$found = $search->next($map);
	ok (!$found, "End of list detected");
	# print Dumper($search), "\n";
	ok (!$search->current(), "Current entry is null at end of list");

	#
	# Test what happens if search does not find any entries
	#
	$search->filterspec( '(cn=Zarquon)' );
	$msg = $search->search();
	ok (($msg->count() == 0), "Search found no entries");
	$found = $search->next();
	ok ((!$found), "next() method returns false when no entries found");

	#
	# Tests for update method
	#

	# Return to the data-driven search
	$search->filterspec( '(&(cn=%given%)(objectclass=person))' );
	$msg = $search->search( $person );
	ok (($search->next() and $search->current()->get('_dn')->[0] eq 'cn=test-1,dc=example,dc=org'),
		"Search finds correct entry to modify");
	# Define the attributes we want to update from the person entry
	my $updateMap = Data::Toolkit::Map->new();
	$updateMap->set('telephoneNumber','phone');
	$updateMap->set('mail','mail');
	$updateMap->set('manager','manager');

	# Data::Toolkit::Entry->debug(1);

	$msg = $search->update($person, $updateMap);
	ok ((!$msg->is_error()), "Update operation completed OK");

	# Redo the search to find the updated entry
	$msg = $search->search( $person );
	ok (($search->next() and $search->current()->get('_dn')->[0] eq 'cn=test-1,dc=example,dc=org'),
		"Search finds correct entry again");
	# Change the list of phone numbers
	$person->set( 'phone', [ '+00', '+111' ] );
	$msg = $search->update($person, $updateMap);
	ok ((!$msg->is_error()), "Update operation with attribute value deletion completed OK");
	# Redo the search to find the updated entry
	$msg = $search->search( $person );
	my $verify = $search->next();
	print "VERIFY: ", Dumper($verify), "\n" if $verbose;
	ok (($verify and (join ',', $verify->get('telephoneNumber')) eq '+00,+111'),
		"Validate updated data");

	# Try with explicitly empty list
	$person->set( 'phone', [] );
	$msg = $search->update($person, $updateMap);
	ok ((!$msg->is_error()), "Update operation with empty list of phone values");
	# Redo the search to find the updated entry
	$msg = $search->search( $person );
	$verify = $search->next();
	print "VERIFY: ", Dumper($verify), "\n" if $verbose;
	ok (($verify and !$verify->get('telephoneNumber')),
		"Validate updated data");

	# Now check that we can delete the mail attribute entirely
	# Start by checking that the attribute currently exists
	ok (defined($verify->get('mail')), "Mail attribute is currently defined");
	$person->delete( 'mail' );
	$msg = $search->update($person, $updateMap);
	ok ((!$msg->is_error()), "Deleting 'mail' attribute");
	# Redo the search to find the updated entry
	$msg = $search->search( $person );
	$verify = $search->next();
	print "VERIFY: ", Dumper($verify), "\n" if $verbose;
	ok (($verify and !defined($verify->get('mail'))),
		"Validate updated data");


	#
	# Test effect of empty update entry
	#
	my $empty = Data::Toolkit::Entry->new();
	my $emptyMap = Data::Toolkit::Map->new();
	# Redo the search to find the updated entry
	$msg = $search->search( $person );
	ok ((!$msg->is_error()), "Redo search");
	my $ent = $search->next();
	ok ((defined($ent)), "Entry found");
	$msg = $search->update($empty, $emptyMap);
	ok ((!$msg->is_error()), "Update operation with empty entry and map");
	print "ERR: ", $msg->error(), "\n" if $msg->is_error();

	# print Dumper($ent), "\n";

	# print $search->current()->dump(), "\n";

	# Build an entry to delete
	my $victim = Data::Toolkit::Entry->new();
	$victim->set( '_dn', [$ent->get('_dn')] );
	# print "About to delete ", $ent->get('_dn')->[0], "\n";
	$msg = $search->delete( $victim );
	ok ((!$msg->is_error()), "Delete an entry");

	# Check that it has gone
	$msg = $search->search( $person );
	ok ((!$msg->is_error()), "Searching for the deleted entry");
	ok ((!defined($search->next())), "Checking that entry has gone");

	$msg = $search->delete( $victim );
	ok (($msg->is_error() and ($msg->error_name() eq 'LDAP_NO_SUCH_OBJECT')), "Delete the same entry again");
	# print "ERR: ", $msg->error_name(), "\n" if $msg->is_error();
}

