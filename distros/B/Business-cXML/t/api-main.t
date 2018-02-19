#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Trap qw(:stderr);

use File::Slurp;

use XML::LibXML;
XML::LibXML->new()->load_catalog('t/xml-catalog/catalog.xml');

use Business::cXML;

plan tests => 10;

## Creator
#
my $cxml = Business::cXML->new();
isa_ok($cxml, 'Business::cXML', 'Bare cXML object created');
cmp_deeply(
	$cxml,
	noclass({
		local           => '',
		remote          => undef,
		secret          => undef,
		sender_callback => undef,
		log_level       => CXML_LOG_NOTHING,
		log_callback    => bool(1),
		routes => {
			Profile => {
				__handler => bool(1),
			},
		},
	}),
	'Bare cXML object has expected structure'
);

sub _mylog {
	my (undef) = @_;
}
sub _test {
	my (undef) = @_;
}
$cxml = Business::cXML->new(
	local           => 'local',
	remote          => 'remote',
	secret          => 'secret',
	sender_callback => 'sender',
	log_level       => CXML_LOG_INFO,
	log_callback    => \&_mylog,
	handlers        => {
		Test => {
			__handler => \&_test,
		},
	},
);
cmp_deeply(
	$cxml,
	noclass({
		local           => 'local',
		remote          => 'remote',
		secret          => 'secret',
		sender_callback => undef,
		log_level       => CXML_LOG_INFO,
		log_callback    => \&_mylog,
		routes          => {
			Profile => {
				__handler => bool(1),
			},
			Test => {
				__handler => \&_test,
			},
		},
	}),
	'Full cXML object has expected structure'
);
$cxml->{log_callback} = undef;
$cxml->log_callback(\&_mylog);
cmp_deeply($cxml->{log_callback}, \&_mylog, 'Manually changing the log callback works');

## Logging, error handling
#
my $reqStr = read_file('t/xml-assets/punchoutsetup1-request.xml');

$cxml = Business::cXML->new(log_level => CXML_LOG_INFO);
trap { $cxml->process(scalar(read_file('t/xml-assets/profile-request.xml'))); };
#diag($trap->stderr);
ok($trap->stderr =~ /^cXML\[info\]: process.*received request -- .*cXML\[info\]: process.*responding with 2xx -- /s, 'Logging output looks adequate');

$cxml = Business::cXML->new(log_level => CXML_LOG_ERROR);
sub _failreq {
	my ($cxml, $req, $res) = @_;
	$res->status(200);
	$res->xml_payload->add('Invalid', 'This node is invalid', foo => 'bar');
};

# Garbage request
$cxml = Business::cXML->new(log_level => CXML_LOG_WARNING);
trap { $cxml->process(scalar(read_file('t/xml-assets/garbage-request.xml'))); };
#diag($trap->stderr);
ok($trap->stderr =~ /^cXML\[warning\]: process.* XML validation failure:/s, '');

# 200 / invalid XML
$cxml->on('PunchOutSetup' => { __handler => \&_failreq });
trap { $cxml->process($reqStr); };
#diag($trap->stderr);
ok($trap->stderr =~ /^cXML\[error\]: process.*validity error.*Invalid/s, 'Invalid XML payload triggers expected error');

# 4xx at caller handler level
$cxml = Business::cXML->new(
	log_level => CXML_LOG_WARNING,
	handlers  => { PunchOutSetup => { __handler => sub { $_[2]->status(403, 'You cannot do this, ever'); }, }, },
);
trap { $cxml->process($reqStr); };
#diag($trap->stderr);
ok($trap->stderr =~ /^cXML\[warning\]: process.* responding with 4xx -- .*code="403"/s, 'Error 403 goes through');

# 5xx at caller handler level
$cxml = Business::cXML->new(
	log_level => CXML_LOG_WARNING,
	handlers  => { PunchOutSetup => { __handler => sub { $_[2]->status(560, 'This is freaking me out!'); }, }, },
);
trap { $cxml->process($reqStr); };
#diag($trap->stderr);
ok($trap->stderr =~ /^cXML\[error\]: process.* responding with 5xx -- .*code="560"/s, 'Error 560 goes through');

# Invalid status from caller handler
$cxml = Business::cXML->new(
	log_level => CXML_LOG_WARNING,
	handlers  => { PunchOutSetup => { __handler => sub { $_[2]->status(655, 'Incredible status'); }, }, },
);
trap { $cxml->process($reqStr); };
#diag($trap->stderr);
ok($trap->stderr =~ /^cXML\[error\]: process.* responding with 5xx -- .*Unsupported actual status code '655'./s, 'Unsupported status code gets trapped into a 500');


