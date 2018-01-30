#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::MockModule;
use File::Slurp;
use LWP::UserAgent;

use XML::LibXML;
XML::LibXML->new()->load_catalog('t/xml-catalog/catalog.xml');

use XML::LibXML::Ferry;
use Business::cXML;

use lib 't/';
use Test::cXML qw(comparable);

plan tests => 10;

my $cxml = Business::cXML->new(
	remote => 'https://example.com/ecommerce',
	secret => 'password',
#	log_level => CXML_LOG_WARNING,
);

my $req = $cxml->new_request('Profile');
$req->from(id => 'remotehost', domain => 'TEST');
$req->to(  id => 'localhost',  domain => 'TEST');
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => scalar($req->toString))),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/profile-request.xml')),
	'Profile request matches expectations'
);

$cxml->{secret} = undef;
$req = $cxml->new_request();
$req->type('Profile');
$req->is_test(1);
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => scalar($req->toString))),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/profile2-request.xml')),
	'Profile 2 request matches expectations'
);

cmp_deeply(
	comparable(XML::LibXML->load_xml(string => scalar(Business::cXML::Transmission->new(scalar(read_file('t/xml-assets/punchoutsetup1-request.xml')))->toString))),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/punchoutsetup1-request.xml')),
	'XML round-trip punch-out request 1 is consistent'
);
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => scalar(Business::cXML::Transmission->new(scalar(read_file('t/xml-assets/punchoutsetup8-request.xml')))->toString))),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/punchoutsetup8-request.xml')),
	'XML round-trip punch-out request 8 is consistent'
);

my $lwp = Test::MockModule->new('LWP::UserAgent');
$lwp->mock('new', sub {
	my ($class) = @_;
	my $self = {
		agent   => 'Mock LWP',
		timeout => 60,
	};
	return bless $self, $class;
});
$lwp->mock('timeout', sub {
	my ($self, $arg) = @_;
	$self->{timeout} = $arg if defined $arg;
	return $self->{timeout};
});
$lwp->mock('agent', sub {
	my ($self, $arg) = @_;
	$self->{agent} = $arg if defined $arg;
	return $self->{agent};
});
$lwp->mock(is_success => 1);
$lwp->mock(decoded_content => scalar(read_file('t/xml-assets/profile-response.xml')));
$lwp->mock('post', sub {
	my ($self, $url, %args) = @_;
	return $self;
});

my $res = $cxml->send($req);
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => scalar($res->toString))),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/profile-response.xml')),
	'Fake network I/O behaved as expected'
);
$res = $cxml->send($req->{string});  # Should exist, send() calls freeze()
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => scalar($res->toString))),
	comparable(XML::LibXML->load_xml(location => 't/xml-assets/profile-response.xml')),
	'Fake network I/O behaved as expected'
);

$lwp->mock(decoded_content => scalar(read_file('t/xml-assets/garbage-response.xml')));
$res = $cxml->send($req);
ok(!defined $res, 'Garbage response returns undefined');

$lwp->mock(decoded_content => scalar(read_file('t/xml-assets/unintelligible-response.xml')));
$res = $cxml->send($req);
ok(!defined $res, 'Unintelligible XML response returns undefined');

$lwp->mock(is_success => 0);
$res = $cxml->send($req);
ok(!defined $res, 'Network failure returns undefined');

$lwp->mock(is_success => 1);
$req->thaw();
$req->xml_payload->add('GarbageNode', 'This triggers a validation error');
$res = $cxml->send($req);
ok(!defined $res, 'Invalid request returns undefined');

