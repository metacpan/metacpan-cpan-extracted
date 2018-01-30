#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Deep;

use XML::LibXML;
XML::LibXML->new()->load_catalog('t/xml-catalog/catalog.xml');

use XML::LibXML::Ferry;

use Business::cXML;

# We cover:
use Business::cXML::Credential;

plan tests => 8;

my $c;
my $d;
my $h;

## Bare
#
$c = Business::cXML::Credential->new();
isa_ok($c, 'Business::cXML::Credential', 'Bare creation yields object');
cmp_deeply(
	$c,
	noclass({
		_nodeName => 'Sender',
		_note     => undef,
		domain    => 'NetworkId',
		id        => ' ',
		secret    => undef,
		useragent => undef,
		type      => undef,
		lang      => undef,
		contact   => undef,
	}),
	'Bare creation yields expected structure'
);

## Hash
#
$c = Business::cXML::Credential->new({
	_nodeName => 'To',
	domain    => 'DUNS',
	id        => '123456@DUNS',
});
cmp_deeply(
	$c,
	noclass({
		_nodeName => 'To',
		_note     => undef,
		domain    => 'DUNS',
		id        => '123456@DUNS',
		secret    => undef,
		useragent => undef,
		type      => undef,
		lang      => undef,
		contact   => undef,
	}),
	'Hash creation yields expected structure'
);

## XML round-trip
#
$d = XML::LibXML->load_xml(string => '<From><Credential domain="DUNS"><Identity>Zubermann</Identity></Credential></From>')->documentElement;
$a = Business::cXML::Credential->new($d);
cmp_deeply($a->_nodeName, 'From', 'Loading from XML recognizes node name');
cmp_deeply($a->to_node($d)->toHash, $d->toHash, 'Round-trip from XML back to XML is consistent');

$d = XML::LibXML->load_xml(string => '<From><Credential domain="DUNS" type="real"><Identity> </Identity><SharedSecret>pa$$word</SharedSecret></Credential><UserAgent>Ignore Bot</UserAgent></From>')->documentElement;
$h = $d->toHash;
delete $h->{UserAgent};
cmp_deeply(Business::cXML::Credential->new($d)->to_node($d)->toHash, $h, 'XML round-trip for From without UserAgent');

$d = XML::LibXML->load_xml(string => '<Sender><Credential domain="DUNS" type="real"><Identity>myself</Identity><SharedSecret>pa$$word</SharedSecret></Credential><UserAgent>Ignore Bot</UserAgent></Sender>')->documentElement;
$h = $d->toHash;
$h->{UserAgent} = [{ __attributes => {}, __text => ('Business::cXML.pm ' . $Business::cXML::VERSION) }];
cmp_deeply(Business::cXML::Credential->new($d)->to_node($d)->toHash, $h, 'XML round-trip for Sender overwrites UserAgent');

$d = XML::LibXML->load_xml(string => '<To><Credential domain="DUNS" type="real"><Identity>myself</Identity></Credential><Correspondent preferredLanguage="fr-CA"><Contact role="manager"><Name xml:lang="fr-CA">John Smith</Name></Contact></Correspondent></To>')->documentElement;
cmp_deeply(Business::cXML::Credential->new($d)->to_node($d)->toHash, $d->toHash, 'XML round-trip for To considers Contact');

