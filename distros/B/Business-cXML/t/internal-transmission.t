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

use MIME::Base64;

use lib 't/';
use Test::cXML qw(comparable);

# We cover:
use Business::cXML::Transmission;

use Business::cXML::Credential;

plan tests => 18;

my $d;
my $h;
my $s;
my $t;

$t = Business::cXML::Transmission->new();
isa_ok($t, 'Business::cXML::Transmission', 'Bare creation yields a valid transmission');
cmp_deeply(
	comparable($t),
	noclass({
		string      => undef,
		xml_doc     => undef,
		xml_root    => undef,
		xml_payload => undef,
		payload     => undef,
		timestamp   => 'timestamp',
		epoch       => 'epoch',
		hostname    => 'hostname',
		randint     => 'randint',
		pid         => 'pid',
		test        => 0,
		lang        => 'en-US',
		id          => 'id',
		inreplyto   => undef,
		status      => {
			code        => 200,
			text        => 'OK',
			description => '',
		},
		class  => 2,
		type   => 'Profile',
		from   => {
			_nodeName => 'From',
			_note     => undef,
			domain    => 'NetworkId',
			id        => ' ',
			secret    => undef,
			useragent => undef,
			type      => undef,
			lang      => undef,
			contact   => undef,
		},
		to => {
			_nodeName => 'To',
			_note     => undef,
			domain    => 'NetworkId',
			id        => ' ',
			secret    => undef,
			useragent => undef,
			type      => undef,
			lang      => undef,
			contact   => undef,
		},
		sender => {
			_nodeName => 'Sender',
			_note     => undef,
			domain    => 'NetworkId',
			id        => ' ',
			secret    => undef,
			useragent => undef,
			type      => undef,
			lang      => undef,
			contact   => undef,
		},
	}),
	'Bare creation yields expected structure'
);

$s = read_file('t/xml-assets/punchoutsetup1-request.xml');
$t = Business::cXML::Transmission->new(encode_base64($s, ''));
isa_ok($t, 'Business::cXML::Transmission', 'Parsing Base64-encoded file yields valid transmission');

$d = XML::LibXML->load_xml(string => $s)->documentElement->toHash;
$h = XML::LibXML->load_xml(string => scalar($t->toString))->documentElement->toHash;
cmp_deeply(
	comparable($h),
	comparable($d),
	'XML round-trip preserves structure'
);

$s = read_file('t/xml-assets/unknown-response.xml');
cmp_deeply(
	comparable(XML::LibXML->load_xml(string => scalar(Business::cXML::Transmission->new($s)->toString))),
	comparable(XML::LibXML->load_xml(string => $s)->documentElement),
	'XML round-trip response preserves structure'
);

my $a = $t->toString;
my $b = $t->freeze();
cmp_deeply($a, $b, 'Freezing yields same structure as toString()');
ok(scalar($a) eq scalar($t->toString), 'Frozen IS the same string');
$t->thaw();
ok(!defined $t->{string}, 'Thawing resets internal string');

my $c = Business::cXML::Credential->new(_nodeName => 'From');
$t->from($c);
cmp_deeply($c, $t->from, 'Can set From with object');

$c = Business::cXML::Credential->new(_nodeName => 'To');
$t->to($c);
cmp_deeply($c, $t->to, 'Can set To with object');

$c = Business::cXML::Credential->new(_nodeName => 'Sender');
$t->sender($c);
cmp_deeply($c, $t->sender, 'Can set Sender with object');

$t->from(id => '12345');
ok($t->from->{id} eq '12345' && $t->sender->{id} eq '12345', "Setting From prop also sets Sender's");
$t->sender(id => '23456');
ok($t->from->{id} eq '12345' && $t->sender->{id} eq '23456', "Setting Sender prop after From's is safe");
$t->to(id => '54321');
ok($t->to->{id} eq '54321', 'Setting To prop works');

ok(!$t->is_test, 'Transmission is in production mode by default');
$t->is_test(1);
ok($t->is_test, 'Transmission can be switched to test mode');
$t->is_test(0);
ok(!$t->is_test, 'Transmission can be switched from test back to production mode');

$t->lang('en-GB');
ok($t->lang eq 'en-GB', 'Setting language prop works');

