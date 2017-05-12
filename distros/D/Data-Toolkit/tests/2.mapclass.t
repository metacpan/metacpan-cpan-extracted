#!/usr/bin/perl -w
#
# Tests for Data::Toolkit::Map

use strict;

use lib '../lib';

use Carp;
use Test::Simple tests => 33;

use Data::Dumper;
use Data::Toolkit::Entry;
use Data::Toolkit::Map;

my $map = Data::Toolkit::Map->new();
ok (($map and $map->isa( "Data::Toolkit::Map" )), "Create new Data::Toolkit::Map object");

ok (Data::Toolkit::Map->debug() == 0, "Debug level should start at zero");

ok (Data::Toolkit::Map->debug(1) == 1, "Setting debug level to 1");
# my $map2 = Data::Toolkit::Map->new();
# ok (($map2 and $map2->isa( "Data::Toolkit::Map" )), "Create new Data::Toolkit::Map object");
ok (Data::Toolkit::Map->debug(0) == 0, "Setting debug level to 0");

ok ( !defined($map->outputs()->[0]), "No outputs are defined yet");
ok ( ($map->set('sn','surname') eq 'surname'), "Setting an attribute-to-attribute mapping");
my $res = $map->set('cn',['Andrew Findlay','A J Findlay']);
ok ( ((scalar @$res) == 2), "Setting a fixed attribute mapping");
# print "SET: ", (join ",", $map->set('cn',['Andrew Findlay','A J Findlay'])), "\n";
# print "Outputs: ", (join ",",$map->outputs()), "\n";
ok ( ((join ",",$map->outputs()) eq 'cn,sn'), "Map has right outputs" );

# The default is for case-insensitive attribute names so test that
$res = $map->set('CamelCase',['Dromedary']);
ok ( ((scalar @$res) == 1), "Setting a fixed attribute mapping with CamelCase name");
# print "OUT: " . (join ",",$map->outputs()) . "\n";
ok ( ((join ",",$map->outputs()) eq 'camelcase,cn,sn'), "Map has right outputs" );

my $beast = $map->generate( 'cAMELcase' );
ok (($beast and ($beast->[0] eq 'Dromedary')), "Map returns correct result if attribute name given in wrong case");

sub buildPhone {
	return [ "+44 " . "1234 567890" ];
}

ok ( $map->set('phone', \&buildPhone), "Setting a procedure mapping");

ok ( $map->set('mail', sub { return "test" . '@' . "example.org" }), "Setting a closure mapping");

ok ( !defined($map->generate( 'noSuchAttrib' )), "Generate from undefined attrib returns undefined" );
#print Dumper($map->generate('phone'));
my $tel = $map->generate('phone');
ok (($tel and ($tel->[0] eq '+44 1234 567890')), "procedural mapping with no entry" );

my $entry = Data::Toolkit::Entry->new();
$entry->set('voice',['xyzzy']);


sub retNull {
	return undef;
}
ok ( $map->set('nada', \&retNull), "Setting a procedure to return undef");

ok ( !defined($map->generate( 'nada' )), "Generate from procedure returning undef returns undefined" );

my $currOut = join ':', $map->outputs();
$currOut =~ s/mail://;
$map->unset('mail');
ok (((join ':',$map->outputs()) eq $currOut), "Unset removes a mapping completely");

# Tests for missing values while mapping

# An entry with a variety of different contents
$entry = Data::Toolkit::Entry->new();
$entry->set('nada', undef);
$entry->set('blank', []);
$entry->set('null', [ undef ]);
$entry->set('empty', ['']);
$entry->set('thing', ['woohoo!']);
$entry->set('double', ['one', 'two']);

# Build a map that just copies stuff straight through
my $map3 = Data::Toolkit::Map->new();
$map3->set('missing','missing');
$map3->set('nada','nada');
$map3->set('blank','blank');
$map3->set('null','null');
$map3->set('empty','empty');
$map3->set('thing','thing');
$map3->set('double','double');

## print "Map: ", Dumper($map3), "\n";

# First try this with the default behaviour for missing attributes and values
my $result = $map3->newEntry( $entry );

my $value = $result->get('missing');
ok ( (not defined($value)), "Mapping an attribute that is missing from the source entry should by default not produce an attribute in the result");

# This should be the same as 'missing' above, as Data::Toolkit::Entry->set will delete
# any attribute that is assigned an undef value.
#
$value = $result->get('nada');
ok ( (not defined($value)), "Mapping an attribute that is undef in the source entry should by default produce undef in the result");

$value = $result->get('blank');
## print "Source: ", Dumper($entry), "\n";
## print "Result: ", Dumper($result), "\n";
ok ( ($value and (ref $value eq 'ARRAY') and ((scalar @$value) == 0)),
	"Mapping an attribute that is an empty array in the source entry should by default produce an empty array in the result" );

$value = $result->get('null');
ok ( ($value and (ref $value eq 'ARRAY') and ((scalar @$value) == 1) and (not defined($value->[0])) ),
	"Mapping an attribute that contains a single undef value should by default produce the same in the result" );

$value = $result->get('empty');
ok ( ($value and ($value->[0] eq '')),
	"Mapping an attribute that contains a single empty string should by default produce the same in the result" );

$value = $result->get('thing');
ok ( ($value and ($value->[0] eq 'woohoo!')),
	"Mapping an attribute that contains a single non-empty string should by default produce the same in the result" );

$value = $result->get('double');
ok ( ($value and ($value->[0] eq 'one') and ($value->[1] eq 'two')),
	"Mapping an attribute that contains non-empty strings should by default produce the same in the result" );


# Build another map that just copies stuff straight through
# but this one gets non-default missing-value behaviour
my $map4 = Data::Toolkit::Map->new( {
	defaultMissingValueBehaviour => {
                        missing => 'delete',
                        noValues => 'delete',
                        nullValue => 'delete',
                        emptyString => 'delete',
	}
} );
$map4->set('missing','missing');
$map4->set('nada','nada');
$map4->set('blank','blank');
$map4->set('null','null');
$map4->set('empty','empty');
$map4->set('thing','thing');
$map4->set('double','double');

# print "Map: ", Dumper($map4), "\n";

# Data::Toolkit::Map->debug(1);
$result = $map4->newEntry( $entry );

$value = $result->get('nada');
ok ( (not defined($value)), "Missing attribute should stay missing" );

$value = $result->get('blank');
# print "Result: ", Dumper($result), "\n";
ok ( (not defined($value)), "Attribute with empty array should be deleted" );

$value = $result->get('thing');
ok ( ($value and ($value->[0] eq 'woohoo!')), "Attribute with non-empty values should be copied as-is" );

# Result generator
sub map5helper {
	my ($attr, $wantarray, $entry) = @_;

	my $res = [ "new value for $attr" ];
	return $wantarray ? @$res : $res;
}

# Build another map that just copies stuff straight through
# but this one gets code to generate the results
my $map5 = Data::Toolkit::Map->new( {
	defaultMissingValueBehaviour => {
                        missing => \&map5helper,
                        noValues => \&map5helper,
                        nullValue => \&map5helper,
                        emptyString => \&map5helper,
	}
} );
$map5->set('missing','missing');
$map5->set('nada','nada');
$map5->set('blank','blank');
$map5->set('null','null');
$map5->set('empty','empty');
$map5->set('thing','thing');
$map5->set('double','double');

$result = $map5->newEntry( $entry );

$value = $result->get('nada');
ok ( ($value and ($value->[0] eq 'new value for nada')), "missing attr should be replaced by output from callback" );

$value = $result->get('blank');
ok ( ($value and ($value->[0] eq 'new value for blank')), "attr with no values should be replaced by output from callback" );

$value = $result->get('null');
ok ( ($value and ($value->[0] eq 'new value for null')), "attr with null value should be replaced by output from callback" );

$value = $result->get('empty');
ok ( ($value and ($value->[0] eq 'new value for empty')), "attr with empty string should be replaced by output from callback" );

$value = $result->get('thing');
ok ( ($value and ($value->[0] eq 'woohoo!')), "Attribute with non-empty values should be copied as-is" );

