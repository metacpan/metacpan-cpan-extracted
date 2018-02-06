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
use Business::cXML::Amount;
#use Business::cXML::Amount::TaxDetail;

plan tests => 15;

my $a;
my $d;
my $h;

## Bare
#
$a = Business::cXML::Amount->new();
isa_ok($a, 'Business::cXML::Amount', 'Minimal object creation');
cmp_deeply(
	$a,
	noclass({
		_nodeName       => 'Amount',
		currency        => 'USD',
		amount          => '0.00',
		description     => undef,
		type            => undef,
		fees            => [],
		tracking_domain => undef,
		tracking_id     => undef,
		tax_details     => [],
		taxadj_details  => [],
		category        => '',
		region          => undef,
	}),
	'Minimal object is as expected'
);

## Hash
#
$a = Business::cXML::Amount->new({
	amount      => 29.99,
	description => { full => 'The price for this item' },
	tax_details => { category => 'gst', tax => { amount => 4.99 } },
});
cmp_deeply(
	$a,
	noclass({
		_nodeName       => 'Amount',
		currency        => 'USD',
		amount          => 29.99,
		description     => {
			_nodeName => 'Description',
			lang      => 'en-US',
			short     => undef,
			full      => 'The price for this item',
		},
		type            => undef,
		fees            => [],
		tracking_domain => undef,
		tracking_id     => undef,
		tax_details     => [{
			_nodeName   => 'TaxDetail',
			basis       => undef,
			category    => 'gst',
			percent     => undef,
			purpose     => undef,
			description => undef,
			tax       => {
				_nodeName       => 'TaxAmount',
				currency        => 'USD',
				amount          => 4.99,
				description     => undef,
				type            => undef,
				fees            => [],
				tracking_domain => undef,
				tracking_id     => undef,
				tax_details     => [],
				taxadj_details  => [],
				category        => '',
				region          => undef,
			},
		}],
		taxadj_details  => [],
		category        => '',
		region          => undef,
	}),
	'Object from hash has expected information'
);

## XML round-trip
#
$d = XML::LibXML->load_xml(string => '<FeeAmount><Money currency="USD">79.99</Money></FeeAmount>')->documentElement;
$a = Business::cXML::Amount->new($d);
cmp_deeply($a->_nodeName, 'FeeAmount', 'Loading from XML recognizes node name');
cmp_deeply($a->to_node($d)->toHash, $d->toHash, 'Round-trip from XML back to XML is consistent');

## Specific variations
#

$d = XML::LibXML->load_xml(string => '<AvailablePrice type="lowest"><Money currency="USD">79.99</Money><Description xml:lang="fr-CA">Longue description</Description></AvailablePrice>')->documentElement;
cmp_deeply(Business::cXML::Amount->new($d)->to_node($d)->toHash, $d->toHash, 'XML round-trip for described AvailablePrice');

$d = XML::LibXML->load_xml(string => '<AvailablePrice><Money currency="USD">79.99</Money><Description xml:lang="fr-CA">Longue description</Description></AvailablePrice>')->documentElement;
$h = $d->toHash;
$h->{__attributes}{type} = 'other';
cmp_deeply(Business::cXML::Amount->new($d)->to_node($d)->toHash, $h, 'XML AvailablePrice is valid despite incomplete input');

$d = XML::LibXML->load_xml(string => '<Shipping><Money currency="CAD">17.99</Money><Description xml:lang="fr-CA">Long periple</Description></Shipping>')->documentElement;
cmp_deeply(Business::cXML::Amount->new($d)->to_node($d)->toHash, $d->toHash, 'XML round-trip for minimal Shipping');

$d = XML::LibXML->load_xml(string => '<Shipping trackingDomain="td" trackingId="ti"><Money currency="CAD">17.99</Money><Description xml:lang="fr-CA">Long periple</Description></Shipping>')->documentElement;
cmp_deeply(Business::cXML::Amount->new($d)->to_node($d)->toHash, $d->toHash, 'XML round-trip for full Shipping');

$d = XML::LibXML->load_xml(string => '<Tax><Money currency="CAD">21.95</Money><Description xml:lang="fr-CA">General Sales Tax</Description><TaxDetail category="gst" percentageRate="8"><TaxAmount><Money currency="CAD">12.97</Money></TaxAmount></TaxDetail></Tax>')->documentElement;
cmp_deeply(Business::cXML::Amount->new($d)->to_node($d)->toHash, $d->toHash, 'XML round-trip for Tax with minimal TaxDetail');

$d = XML::LibXML->load_xml(string => '<Tax><Money currency="CAD">21.95</Money><Description xml:lang="fr-CA">General Sales Tax</Description><TaxDetail category="gst" percentageRate="8"><TaxableAmount><Money currency="CAD">9.95</Money></TaxableAmount><TaxAmount><Money currency="CAD">12.97</Money></TaxAmount><Description xml:lang="en-US">taxes</Description></TaxDetail></Tax>')->documentElement;
cmp_deeply(Business::cXML::Amount->new($d)->to_node($d)->toHash, $d->toHash, 'XML round-trip for Tax with full TaxDetail');

$d = XML::LibXML->load_xml(string => '<TaxAdjustment><Money currency="CAD">21.95</Money><TaxAdjustmentDetail category="additional" region="C"><Money currency="CAD">12.97</Money></TaxAdjustmentDetail></TaxAdjustment>')->documentElement;
cmp_deeply(Business::cXML::Amount->new($d)->to_node($d)->toHash, $d->toHash, 'XML round-trip for TaxAdjustment');

$d = XML::LibXML->load_xml(string => '<TaxAdjustment><Money currency="CAD">21.95</Money><TaxAdjustmentDetail category="additional"><Money currency="CAD">12.97</Money></TaxAdjustmentDetail></TaxAdjustment>')->documentElement;
cmp_deeply(Business::cXML::Amount->new($d)->to_node($d)->toHash, $d->toHash, 'XML round-trip for TaxAdjustment without detail region');

## Safe ignores
#

cmp_deeply(
	Business::cXML::Amount->new({
		currency    => 'CAD',
		amount      => 37.95,
		type        => 'lowest',
		description => { full => 'Full description' },
	})->to_node($d)->toHash,
	noclass({
		__attributes => {},
		__text       => '',
		Money => [{
			__attributes => { currency => 'CAD' },
			__text       => '37.95',
		}],
	}),
	'Type and description ignored for a generic Amount'
);

## Conditional defaults
#

cmp_deeply(
	Business::cXML::Amount->new('Tax', { amount => 4.95 })->to_node($d)->toHash,
	noclass({
		__attributes => {},
		__text       => '',
		Money => [{
			__attributes => { currency => 'USD' },
			__text       => '4.95',
		}],
		Description => [{
			__attributes => {
				'{http://www.w3.org/XML/1998/namespace}lang' => 'en-US',
			},
			__text => '',
		}],
	}),
	'A Tax always includes a description'
);
