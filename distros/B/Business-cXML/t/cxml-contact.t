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
use Business::cXML::Contact;

plan tests => 10;

my $c;
my $d;

## Bare
#
$c = Business::cXML::Contact->new();
isa_ok($c, 'Business::cXML::Contact', 'New minimal contact can be created');
cmp_deeply(
	$c,
	noclass({
		_nodeName => 'Contact',
		role      => undef,
		lang      => 'en-US',
		name      => '',
		emails    => [],
		urls      => [],
		phones    => [],
		faxes     => [],
		postals   => [],
	}),
	'Minimal contact is as expected'
);

## From hash
#
$c = Business::cXML::Contact->new({
	role    => 'manager',
	name    => 'John Smith',
	lang    => 'fr-CA',
	emails  => 'jsmith@example.com',
	urls    => 'https://example.com/',
	phones  => { area_code => '888', number => '555-1212' },
	faxes   => { area_code => '877', number => '5551212' },
	postals => { delivertos => 'John Smith', streets => '123 Main St.', city => 'Toronto', country => 'Canada' },
});
isa_ok($c->phones->[0], 'Business::cXML::Address::Number', 'Phone is a Number object');
isa_ok($c->faxes->[0], 'Business::cXML::Address::Number', 'Fax is a Number object');
isa_ok($c->postals->[0], 'Business::cXML::Address::Postal', 'Postal is a Postal object');
cmp_deeply(
	$c,
	noclass({
		_nodeName => 'Contact',
		role      => 'manager',
		name      => 'John Smith',
		lang      => 'fr-CA',
		emails    => [ 'jsmith@example.com' ],
		urls      => [ 'https://example.com/' ],
		phones    => [{
			_nodeName    => 'Phone',
			name         => undef,
			country_iso  => 'US',
			country_code => '1',
			area_code    => '888',
			number       => '555-1212',
			extension    => undef,
		}],
		faxes => [{
			_nodeName    => 'Fax',
			name         => undef,
			country_iso  => 'US',
			country_code => '1',
			area_code    => '877',
			number       => '5551212',
			extension    => undef,
		}],
		postals   => [{
			_nodeName => 'PostalAddress',
			name        => undef,
			delivertos  => [ 'John Smith' ],
			streets     => [ '123 Main St.' ],
			city        => 'Toronto',
			muni        => undef,
			state       => undef,
			code        => undef,
			country_iso => '',
			country     => 'Canada',
		}],
	}),
	'Minimal contact is as expected'
);

## From node
#
$d = XML::LibXML->load_xml(location => 't/xml-assets/punchoutsetup1-request.xml')->getElementsByTagName('Contact')->[0];
$c = Business::cXML::Contact->new($d);
isa_ok($c, 'Business::cXML::Contact', 'Creation from node');
cmp_deeply(
	$c,
	noclass({
		_nodeName => 'Contact',
		role      => undef,
		name      => 'John Smith',
		lang      => 'en-US',
		emails    => [ '1234@remotehost' ],
		urls      => [],
		phones    => [{
			_nodeName    => 'Phone',
			name         => undef,
			country_iso  => 'CA',
			country_code => '1',
			area_code    => '888',
			number       => '5551212',
			extension    => undef,
		}],
		faxes   => [],
		postals => [],
	}),
	'Creation from node yielded expected info'
);

## XML round-trip
#
cmp_deeply(
	$d->toHash,
	$c->to_node($d)->toHash,
	'Round-trip from XML back to XML is consistent'
);
$c->role('public defender');
cmp_deeply(
	$c->to_node($d)->toHash->{__attributes}{role},
	'public defender',
	'XML output preserves optional role'
);
