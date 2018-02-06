#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Deep;

use File::Slurp;

use XML::LibXML;
XML::LibXML->new()->load_catalog('t/xml-catalog/catalog.xml');

use XML::LibXML::Ferry;
use Business::cXML;
use Business::cXML::Transmission;

use lib 't/';
use Test::cXML qw(comparable);

plan tests => 19;

my $cxml = Business::cXML->new(local => 'https://example.com/api/cxml');

## Ping-pong
#
my $libxml_pong = XML::LibXML->load_xml(location => 't/xml-assets/ping-response.xml');
my $pong = XML::LibXML->load_xml(string => $cxml->process(''));
cmp_deeply(
	comparable($pong),
	comparable($libxml_pong),
	'Correct ping-pong response'
);

## Unknown request type
#
my $string_pos_req = read_file('t/xml-assets/punchoutsetup1-request.xml');
my $libxml_unknown = XML::LibXML->load_xml(location => 't/xml-assets/unknown-response.xml');
my $unknown = XML::LibXML->load_xml(string => $cxml->process($string_pos_req));
cmp_deeply(
	comparable($unknown),
	comparable($libxml_unknown),
	'Correct response to unknown request'
);

## Punch-out setup
#
our $nth = 0;
sub _pos {
	my ($cxml, $req, $res) = @_;
	cmp_deeply($req->id, $res->inreplyto, 'Response inreplyto matches request ID');
	cmp_deeply($req->is_test, $res->is_test, 'Response deployment mode matches request');
	$res->status(200);
	$res->payload->url('https://example.com/punchout_login') unless $nth;
	$nth++;
	$req->payload->contacts->[0]->{phones} = [];  # We don't test that depth here
	cmp_deeply(
		$req->payload->contacts,
		noclass([{
			_nodeName => 'Contact',
			lang      => 'en-US',
			name      => 'John Smith',
			emails    => [ '1234@remotehost' ],
			faxes     => [],
			phones    => [],
			postals   => [],
			role      => undef,
			urls      => [],
		}]),
		'Punch-out request contacts'
	);
	# We don't test addresses, shipto here
	$req->payload->shipto->{carriers} = [];
	$req->payload->shipto->{transports} = [];
	$req->payload->shipto->address->set(
		phone => undef,
		fax   => undef,
		email => undef,
		url   => undef,
	);
	$req->payload->shipto->address->postal->set(name => undef);
	cmp_deeply(
		$req->payload->shipto,
		noclass({
			_nodeName  => 'ShipTo',
			carriers   => [],
			transports => [],
			address    => {
				_nodeName => 'Address',
				name      => 'John Smith',
				lang      => 'en-US',
				phone     => undef,
				fax       => undef,
				email     => undef,
				url       => undef,
				postal => {
					_nodeName   => 'PostalAddress',
					name        => undef,
					delivertos  => [ 'John Smith' ],
					streets     => [ '123 Main St.' ],
					city        => 'Metropolis',
					muni        => 'N/A',
					state       => 'ON',
					code        => 'H3C 3P3',
					country     => 'Canada',
					country_iso => 'CA',
				},
			},
		}),
		'Punch-out request ship-to address'
	);
	return;
}
$cxml->on(
	PunchOutSetup => {
		__handler        => \&_pos,
		operationAllowed => 'create',
	},
);
my $pos_response = XML::LibXML->load_xml(string => $cxml->process($string_pos_req));
cmp_deeply(
	comparable($pos_response),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/punchoutsetup1-response.xml')),
	'XML response to punch-out setup request 1 matches expectations'
);

# We only care about running _pos() a second time
$pos_response = $cxml->process(scalar(read_file('t/xml-assets/punchoutsetup2-request.xml')));
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => $pos_response)),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/punchoutsetup2-response.xml')),
	'XML response to punch-out setup request 2 matches expectations'
);

## Sender validation (success)
#
sub _sender {
	my ($cxml, $sender, $from) = @_;
	return 23;
}
$cxml->sender_callback(\&_sender);

## Profile
#
my $s = read_file('t/xml-assets/profile-request.xml');
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => $cxml->process($s))),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/profile-response.xml')),
	'XML response to profile request matches expectations'
);

## Sender validation (failure)
#
sub _false { return undef; }
$cxml->sender_callback(\&_false);
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => $cxml->process($s))),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/unauthorized-response.xml')),
	'Sender validation failure yields 401 response'
);

## Alternate user name sources
#
$cxml = Business::cXML->new();
$cxml->on(PunchOutSetup => { __handler => sub {
	my ($cxml, $req, $res) = @_;
	cmp_deeply($req->payload->contacts, noclass([{
		_nodeName => 'Contact',
		lang      => 'en-US',
		name      => 'John Smith',
		emails    => [ '1234@remotehost' ],
		faxes     => [],
		phones    => [],
		postals   => [],
		role      => undef,
		urls      => [],
	}]), 'Extrinsic UserFullName is recognized');
}});
$s = read_file('t/xml-assets/punchoutsetup3-request.xml');
$cxml->process($s);

$cxml = Business::cXML->new();
$cxml->on(PunchOutSetup => { __handler => sub {
	my ($cxml, $req, $res) = @_;
	cmp_deeply($req->payload->contacts, noclass([{
		_nodeName => 'Contact',
		lang      => 'en-US',
		name      => 'jsmith',
		emails    => [ '1234@remotehost' ],
		faxes     => [],
		phones    => [],
		postals   => [],
		role      => undef,
		urls      => [],
	}]), 'Extrinsic UniqueName is recognized');
}});
$cxml->process(scalar(read_file('t/xml-assets/punchoutsetup4-request.xml')));

$cxml = Business::cXML->new();
$cxml->on(PunchOutSetup => { __handler => sub {
	my ($cxml, $req, $res) = @_;
	cmp_deeply($req->payload->contacts, [], 'No contact on insufficient Extrinsics');
}});
$cxml->process(scalar(read_file('t/xml-assets/punchoutsetup5-request.xml')));
$cxml->process(scalar(read_file('t/xml-assets/punchoutsetup6-request.xml')));
$cxml->process(scalar(read_file('t/xml-assets/punchoutsetup7-request.xml')));

