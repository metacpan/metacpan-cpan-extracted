#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Deep;

use XML::LibXML;
XML::LibXML->new()->load_catalog('t/xml-catalog/catalog.xml');

use XML::LibXML::Ferry;

# We cover:
use Business::cXML::Description;

plan tests => 6;

my $a = Business::cXML::Description->new({
	lang  => 'fr-CA',
	short => 'Short desc',
	full  => 'This is the full mandatory description'
});

isa_ok($a, 'Business::cXML::Description', 'Creation from hash');
cmp_deeply(
	$a,
	noclass({
		_nodeName => 'Description',
		lang      => 'fr-CA',
		short     => 'Short desc',
		full      => 'This is the full mandatory description',
	}),
	'Creation from hash yields expected info'
);

my $d = XML::LibXML->load_xml(string => '<Description xml:lang="fr-CA"> <ShortName> delays </ShortName> We should expect delays. </Description>')->documentElement;

$a = Business::cXML::Description->new($d);

isa_ok($a, 'Business::cXML::Description', 'Creation from node');
cmp_deeply(
	$a,
	noclass({
		_nodeName => 'Description',
		lang      => 'fr-CA',
		short     => 'delays',
		full      => 'We should expect delays.',
	}),
	'Creation from node yields expected info'
);
cmp_deeply(
	$a->to_node($d)->toHash,
	$d->toHash,
	'Round-trip from XML back to XML is consistent'
);

$a->set(short => undef);
cmp_deeply(
	$a->to_node($d)->toHash,
	{
		__attributes => { '{http://www.w3.org/XML/1998/namespace}lang' => 'fr-CA' },
		__text => 'We should expect delays.',
	},
	'Minimal XML is also valid'
);

