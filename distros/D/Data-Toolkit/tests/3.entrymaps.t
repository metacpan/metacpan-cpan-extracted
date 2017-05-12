#!/usr/bin/perl -w
#
# Tests for Data::Toolkit::Map in conjunction with Data::Toolkit::Entry

use strict;

use lib '../lib';

use Carp;
use Test::Simple tests => 21;

use Data::Toolkit::Entry;
use Data::Toolkit::Map;
use Data::Dumper;

my $verbose = 0;
ok (Data::Toolkit::Entry->debug($verbose) == $verbose, "Setting Entry debug level to $verbose");
ok (Data::Toolkit::Map->debug($verbose) == $verbose, "Setting Map debug level to $verbose");


my $map = Data::Toolkit::Map->new();
ok (($map and $map->isa( "Data::Toolkit::Map" )), "Create new Data::Toolkit::Map object");

my $entry = Data::Toolkit::Entry->new({ testMarker => 'xyzzy'});
ok (($entry and $entry->isa( "Data::Toolkit::Entry" )), "Create new Data::Toolkit::Entry object");

ok ($entry->add('surname',['Findlay']), "Add surname attribute");
ok ($entry->add('tele',['0111 222333444']), "Add tele attribute");
ok ($entry->add('fullname',['Andrew Findlay','A J Findlay','Dr A J Findlay']), "Add fullname attribute");

ok ( ($map->set('sn','surname') eq 'surname'), "Setting an attribute-to-attribute mapping");
my $list = $map->set('cn',['Andrew Findlay','A J Findlay']);
ok ( ((@$list) == 2), "Setting a fixed attribute mapping");

sub buildPhone {
	return ["+44 " . "1234 567890"];
}
ok ( $map->set('phone', \&buildPhone), "Setting a procedure mapping");
ok ( $map->set('mail', sub { return ["test" . '@' . "example.org"] }), "Setting a closure mapping");

ok (($map->generate('sn',$entry)->[0] eq 'Findlay'), "Generate using attribute mapping");
ok (($map->generate('cn',$entry)->[0] eq 'Andrew Findlay'), "Generate using fixed mapping");
ok (($map->generate('phone',$entry)->[0] eq '+44 1234 567890'), "Generate using procedure mapping");

sub normalisePhone {
	my $attrib = shift;
	my $entry = shift;

	my $phones = $entry->get('tele');

	my @result;
	while (my $phone = shift @$phones) {
		$phone =~ s/^0/+44 /;
		$phone =~ s/\(0\)//;
		push @result, $phone;
	}

	return \@result;
}
ok ( $map->set('phone', \&normalisePhone), "Resetting a procedure mapping");
# print "PHONE: " . $map->generate('phone',$entry)->[0] . "\n";
ok (($map->generate('phone',$entry)->[0] eq '+44 111 222333444'), "Generate using procedure mapping");

sub firstValue {
	my $source = shift;
	my $attrib = shift;
	my $entry = shift;

	my $list = $entry->get($source);
	return undef if !$list;
	return [ $list->[0] ];
}
ok ( $map->set('fn', sub { return firstValue( 'fullname', @_ ) } ), "Setting a complex closure mapping");
my $closeRes = $map->generate('fn',$entry);
# print "GOT: ", $closeRes->[0], "\n";

ok (( $closeRes->[0] eq 'A J Findlay'), "Closure mapping with parameters");

# print $entry->dump(), "\n";
# print "####\n";

# Data::Toolkit::Entry->debug(1);
# Data::Toolkit::Map->debug(1);

my $newEntry = $entry->map( $map );
# print $newEntry->dump(), "\n";

# print Dumper($newEntry->{config}), "\n";

# Note: this test prods inside the object: dont do it in real code!
ok ( ($newEntry->{config}->{testMarker} eq 'xyzzy'), "New entry contains copy of original config" );

#
# Check mapping where a procedure returns undef
#
my $ent2 = Data::Toolkit::Entry->new();
$ent2->set('att1', ['val1']);
$ent2->set('att2', ['val2']);

sub retNull {
	return undef;
}
my $map2 = Data::Toolkit::Map->new();
$map2->set('res1', 'att1');
$map2->set('res2', \&retNull);

# Apply map to entry, generating a new entry
my $ent3 = $ent2->map( $map2 );
# print Dumper($ent3), "\n";
ok ( ($ent3 and ($ent3->get('res1')->[0] eq 'val1')), "Basic test on map" );
ok ( ($ent3 and !defined($ent3->get('res2'))), "Test procedure returning null in map" );

