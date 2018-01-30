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
use Business::cXML::ShipTo;
use Business::cXML::Transport;
#use Business::cXML::Carrier;

plan tests => 8;

my $s = Business::cXML::ShipTo->new({
	address => {
		name => 'test-address',
	},
	carriers => {
		domain => 'TEST',
		id     => 'TestCarrier',
	},
	transports => {
		contract => 'Detailed contract',
	},
});
isa_ok($s, 'Business::cXML::ShipTo', 'Creation from hash');
isa_ok($s->carriers->[0], 'Business::cXML::Carrier', 'Creation from nested hash');
cmp_deeply(
	$s,
	noclass({
		_nodeName => 'ShipTo',
		address => {
			_nodeName => 'Address',
			lang      => 'en-US',
			name      => 'test-address',
			email     => undef,
			fax       => undef,
			phone     => undef,
			url       => undef,
			postal    => undef,
		},
		carriers => [{
			_nodeName => 'CarrierIdentifier',
			domain    => 'TEST',
			id        => 'TestCarrier',
		}],
		transports => [{
			_nodeName   => 'TransportInformation',
			contacts     => [],
			contract     => 'Detailed contract',
			start        => undef,
			end          => undef,
			means        => undef,
			method       => 'unknown',
			instructions => undef,
		}],
	}),
	'Creation from hash yields expected structure'
);

my $d = XML::LibXML->load_xml(location => 't/xml-assets/punchoutsetup1-request.xml');
$d = $d->documentElement;

my $s2 = Business::cXML::ShipTo->new($d->getElementsByTagName('ShipTo')->[0]);
$s2->set(address => undef);  # Tested elsewhere
isa_ok($s2, 'Business::cXML::ShipTo', 'Creation from node');
cmp_deeply(
	$s2,
	noclass({
		_nodeName  => 'ShipTo',
		address    => undef,
		carriers   => [{
			_nodeName => 'CarrierIdentifier',
			domain    => 'companyName',
			id        => 'FedEx',
		}],
		transports => [{
			_nodeName    => 'TransportInformation',
			contacts     => [],
			contract     => '1868',
			start        => undef,
			end          => undef,
			means        => undef,
			method       => 'air',
			instructions => {
				_nodeName => 'Description',
				lang      => 'en-US',
				short     => 'delays',
				full      => 'We should expect delays.',
			},
		}],
	}),
	'Creation from node found all info'
);

$s2 = Business::cXML::ShipTo->new($d->getElementsByTagName('ShipTo')->[0]);
cmp_deeply(
	$s2->to_node($d)->toHash,
	$d->getElementsByTagName('ShipTo')->[0]->toHash,
	'Round-trip from XML back to XML is consistent'
);

my $s3 = Business::cXML::Transport->new();
cmp_deeply(
	$s3,
	noclass({
		_nodeName    => 'TransportInformation',
		method       => 'unknown',
		means        => undef,
		start        => undef,
		end          => undef,
		contacts     => [],
		contract     => undef,
		instructions => undef,
	}),
	'Create stand-alone transport'
);
cmp_deeply(
	$s3->to_node($d)->toHash,
	{
		__attributes => {},
		__text       => '',
		Route        => [{ __attributes => { method => 'unknown' }, __text => '' }],
	},
	'Minimal transport to XML is valid'
);

