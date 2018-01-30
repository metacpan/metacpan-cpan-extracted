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
use Business::cXML::Address;
#use Business::cXML::Address::Number;
#use Business::cXML::Address::Postal;

plan tests => 11;

## Hash
#
my $a = Business::cXML::Address->new({
	name   => 'John Smith',
	email  => 'jsmith@example.com',
	url    => 'https://example.com/',
	phone  => {
		country_iso => 'CA',
		area_code   => '800',
		number      => '555-1212',
	},
	fax    => {
		_nodeName   => 'Fax',
		country_iso => 'CA',
		area_code   => '866',
		number      => '555-1212',
	},
	postal => {
		name        => 'reception',
		delivertos  => 'John Smith',
		streets     => '123 Main St.',
		city        => 'Metropolis',
		muni        => 'N/A',
		state       => 'ON',
		code        => 'H3C 3P3',
		country     => 'Canada',
		country_iso => 'CA',
	},
});

isa_ok($a, 'Business::cXML::Address', 'Creation from hash');
isa_ok($a->phone, 'Business::cXML::Address::Number', 'Creation from nested hash');
cmp_deeply(
	$a,
	noclass({
		_nodeName => 'Address',
		name      => 'John Smith',
		lang      => 'en-US',
		email     => 'jsmith@example.com',
		url       => 'https://example.com/',
		phone     => {
			_nodeName    => 'Phone',
			name         => undef,
			country_iso  => 'CA',
			country_code => '1',
			area_code    => '800',
			number       => '555-1212',
			extension    => undef,
		},
		fax    => {
			_nodeName    => 'Fax',
			name         => undef,
			country_iso  => 'CA',
			country_code => '1',
			area_code    => '866',
			number       => '555-1212',
			extension    => undef,
		},
		postal => {
			_nodeName   => 'PostalAddress',
			name        => 'reception',
			delivertos  => [ 'John Smith' ],
			streets     => [ '123 Main St.' ],
			city        => 'Metropolis',
			muni        => 'N/A',
			state       => 'ON',
			code        => 'H3C 3P3',
			country     => 'Canada',
			country_iso => 'CA',
		},
	}),
	'Creation from nested hash found all info'
);

## Node
#
my $d = XML::LibXML->load_xml(location => 't/xml-assets/punchoutsetup1-request.xml');
$d = $d->documentElement;

my $a2 = Business::cXML::Address->new($d->getElementsByTagName('Address')->[0]);

isa_ok($a2, 'Business::cXML::Address', 'Creation from node');
cmp_deeply(
	$a2,
	noclass({
		_nodeName => 'Address',
		name      => 'John Smith',
		lang      => 'en-US',
		email     => 'jsmith@example.com',
		url       => 'https://example.com/',
		phone     => {
			_nodeName    => 'Phone',
			name         => 'reception',
			country_iso  => 'CA',
			country_code => '1',
			area_code    => '888',
			number       => '5551212',
			extension    => '8888',
		},
		fax    => {
			_nodeName    => 'Fax',
			name         => undef,
			country_iso  => 'CA',
			country_code => '1',
			area_code    => '866',
			number       => '5551212',
			extension    => undef,
		},
		postal    => {
			_nodeName   => 'PostalAddress',
			name        => 'reception',
			delivertos  => [ 'John Smith' ],
			streets     => [ '123 Main St.' ],
			city        => 'Metropolis',
			muni        => 'N/A',
			state       => 'ON',
			code        => 'H3C 3P3',
			country     => 'Canada',
			country_iso => 'CA',
		},
	}),
	'Creation from node found all info'
);

cmp_deeply(
	$a2->to_node($d)->toHash,
	$d->getElementsByTagName('Address')->[0]->toHash,
	'Round-trip from XML back to XML is consistent'
);

my $fs = Business::cXML::Address::Number->new('Fax');
$fs->fromString('1-877-555-1212 x123');
cmp_deeply(
	$fs,
	noclass({
		_nodeName => 'Fax',
		name         => undef,
		country_iso  => 'US',
		country_code => '1',
		area_code    => '877',
		number       => '5551212',
		extension    => undef,
	}),
	'Parse fax number from string'
);
cmp_deeply($fs->toString, '1-877-555-1212', 'Format number back to string');

$fs->number('123456789');
cmp_deeply($fs->toString, '1-877-123456789', 'Format atypical number to string');

$a2->set(
	email  => undef,
	url    => undef,
	fax    => undef,
	phone  => undef,
);
$a2->postal->set(
	name  => undef,
	muni  => undef,
	state => undef,
	code  => undef,
);
$a2->postal->{streets} = [];  # Hack to reset
cmp_deeply(
	$a2->to_node($d)->toHash,
	{
		__attributes => {},
		__text       => '',
		Name => [{
			__attributes => { '{http://www.w3.org/XML/1998/namespace}lang' => 'en-US' },
			__text       => 'John Smith',
		}],
		PostalAddress => [{
			__attributes => {},
			__text       => '',
			Street       => [{ __attributes => {}, __text => '' }],
			City         => [{ __attributes => {}, __text => 'Metropolis' }],
			Country      => [{
				__attributes => { isoCountryCode => 'CA' },
				__text       => 'Canada',
			}],
			DeliverTo    => [{ __attributes => {}, __text => 'John Smith' }],
		}],
	},
	'Simplest address to node'
);
$a2->set(postal => undef);
cmp_deeply(
	$a2->to_node($d)->toHash,
	{
		__attributes => {},
		__text       => '',
		Name         => [{
			__attributes => { '{http://www.w3.org/XML/1998/namespace}lang' => 'en-US' },
			__text       => 'John Smith',
		}],
	},
	'Simplest address without postal, to node'
);
