#!/usr/bin/perl -w
#
# Tests for Data::Toolkit::Entry

use strict;

use lib '../lib';

use Carp;
use Test::Simple tests => 53;

use Data::Toolkit::Entry;

my $debug = 0;
my $debugTest = 0;

my $res;

#
# Object creation tests
#
my $entry = Data::Toolkit::Entry->new();
ok (($entry and $entry->isa( "Data::Toolkit::Entry" )), "Create new Data::Toolkit::Entry object");

#
# Debugging tests
#
ok (Data::Toolkit::Entry->debug() == 0, "Debug level should start at zero");

ok (Data::Toolkit::Entry->debug(1) == 1, "Setting debug level to 1");
# my $entry2 = Data::Toolkit::Entry->new();
# ok (($entry2 and $entry2->isa( "Data::Toolkit::Entry" )), "Create new Data::Toolkit::Entry object");
ok (Data::Toolkit::Entry->debug($debug) == $debug, "Setting debug level to 0");

#
# Attribute methods
#
ok ( ($entry->set('sn',[]) == 0), "Creating an empty 'sn' attribute" );
ok ( ($entry->add('sn',undef) == 0), "Adding null to the 'sn' attribute" );
ok ( ($entry->add('sn',['One', 'Two']) == 2), "Adding two values to the 'sn' attribute" );
ok ( ($entry->add('sn',['Three', 'Four']) == 4), "Adding two more values to the 'sn' attribute" );

$res = $entry->get('sn');
print "SN: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "Four,One,Three,Two"), "Get all values of 'sn'" );
ok ( ($entry->attribute_match('sn', ['Four','One','Three','Two'])), "attribute_match method on sn");
ok ( (!$entry->attribute_match('sn', ['Five','One','Three','Two'])), "attribute_match method on sn with non-matching list");
ok ( ($entry->attribute_match('noSuch',undef)), "non-existant attribute matches undef list");
ok ( ($entry->attribute_match('noSuch',[])), "non-existant attribute matches empty list");

#
# Test inserts at different places in list
#
ok ( ($entry->add('sn',['apple']) == 5), "Adding one more value to the front of 'sn' attribute" );
$res = $entry->get('sn');
print "SN: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "apple,Four,One,Three,Two"), "Get all values of 'sn'" );

ok ( ($entry->add('sn',['zoonose']) == 6), "Adding one more value to the end of 'sn' attribute" );
$res = $entry->get('sn');
print "SN: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "apple,Four,One,Three,Two,zoonose"), "Get all values of 'sn'" );

ok ( ($entry->add('squabble',['argue']) == 1), "Adding one value to the end of 'squabble' attribute" );
print "SN: ", (join ',', @$res), "\n" if $debugTest;
$res = $entry->get('squabble');
ok ( ((join ',', @$res) eq "argue"), "Get all values of 'squabble'" );

ok ( ($entry->add('mobile',[]) == 0), "Adding empty list to a non-existant attribute" );
$res = $entry->get('mobile');
print "RES: $res - " . (join ',', @$res) . "\n" if $debugTest;
ok ( (defined($res) and $res and !defined($res->[0])), "Fetching an empty attribute");

ok ( !defined($entry->get('noneSuch')), "Fetching a non-existant attribute" );

print $entry->dump() if $debugTest;

ok ( $entry->delete('mobile'), "Deleting attribute" );
ok ( !defined($entry->get('mobile')), "The attribute has gone" );

ok ( !defined($entry->delete('nothing')), "Deleting non-existant attribute" );

ok ( !defined($entry->delete('sn','noSuchValue')), "Deleting non-existant value" );
ok ( ($entry->delete('sn','Three')->[0] eq 'Three'), "Deleting value from 'sn'" );

$res = $entry->get('sn');
print "SN: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "apple,Four,One,Two,zoonose"), "Attribute now has correct values" );
# ok ( ($entry->attributes()->[0] eq 'sn'), "Entry has correct list of attributes" );

#
# Case-sensitivity of attribute names
#
$res = $entry->get('SN');
print "SN: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "apple,Four,One,Two,zoonose"), "Attribute can be retrieved if case is different" );

my $caseEntry = Data::Toolkit::Entry->new( {caseSensitiveNames => 1} );
ok (($caseEntry and $caseEntry->isa( "Data::Toolkit::Entry" )), "Create case-sensitive Data::Toolkit::Entry object");
ok ( ($caseEntry->add('sn',['One', 'Two']) == 2), "Adding two values to the 'sn' attribute" );
ok ( ($caseEntry->add('SN',['Three', 'Four']) == 2), "Adding two values to the 'SN' attribute" );

$res = $caseEntry->get('sn');
print "sn: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "One,Two"), "Attribute 'sn' now has correct values" );
$res = $caseEntry->get('SN');
print "SN: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "Four,Three"), "Attribute 'SN' now has correct values" );

# Data::Toolkit::Entry->debug(1);
# $debugTest=1;

#
# comparators
#

ok ( ($entry->comparator('sn') eq 'caseInsensitive'), "Get comparator from default attribute" );
ok ( ($entry->comparator('mobile','integer') eq 'integer'), "Set comparator" );
ok ( ($entry->comparator('mobile') eq 'integer'), "Get comparator" );
ok ( ($entry->add('mobile',[7,5,3]) == 3), "Adding values to the 'mobile' attribute" );
ok ( ($entry->add('mobile',[40]) == 4), "Adding value to the 'mobile' attribute" );
$res = $entry->get('mobile');
print "mobile: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "3,5,7,40"), "Attribute 'mobile' correctly sorted by numeric values" );

sub myCmp {
	my ($lhs,$rhs) = @_;

	# Rip off first letter
	$lhs =~ s/^.//;
	$rhs =~ s/^.//;

	return $lhs cmp $rhs;
}

ok ( $entry->comparator('mine', \&myCmp), "Set function as comparator");
ok ( ($entry->add('mine',['az','bm','aa']) == 3), "Add three values to 'mine'");
$res = $entry->get('mine');
print "mine: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "aa,bm,az"), "Attribute 'mine' correctly sorted by function" );


#
# Value uniqueness
#

# Data::Toolkit::Entry->debug(1);
# $debugTest=1;

ok ( $entry->uniqueValues('sn'), "Default uniqueValues setting is true" );
ok ( ($entry->uniqueValues('mobile', 0) == 0), "Setting uniqueValues to 0" );
ok ( ($entry->uniqueValues('mobile') == 0), "Checking uniqueValues is still 0" );
ok ( ($entry->add('mobile',[7]) == 5), "Adding duplicate value to the 'mobile' attribute" );
$res = $entry->get('mobile');
print "mobile: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "3,5,7,7,40"), "Attribute 'mobile' correctly sorted by numeric values" );

# Data::Toolkit::Entry->debug(1);
# $debugTest=1;

ok ( ($entry->uniqueValues('street', 0) == 0), "Setting uniqueValues to 0 for 'street'" );
ok ( $entry->comparator('street','caseSensitive'), "Set 'street' to be case-sensitive" );
ok ( ($entry->add('street',['Aberdeen','Bamburgh','Carnforth']) ==3), "Adding values to 'street'" );
ok ( ($entry->add('street',['bamBurgh']) ==4), "Adding another value to 'street'" );
$res = $entry->get('street');
print "street: ", (join ',', @$res), "\n" if $debugTest;
ok ( ((join ',', @$res) eq "Aberdeen,Bamburgh,Carnforth,bamBurgh"), "Attribute 'street' correctly sorted" );

