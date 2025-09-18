#!/usr/bin/env perl

use strict;
use warnings;

use CHI;
use Log::Abstraction;
use Test::Most;
use Test::Mockingbird;
use Test::Needs 'LWP::Simple';
use Test::RequiresInternet ('ip-api.com' => 'http');

BEGIN { use_ok('CGI::Lingua') }

# Mock environment variables
local %ENV = (
	REMOTE_ADDR => '127.0.0.1',
	HTTP_USER_AGENT => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
	HTTP_ACCEPT_LANGUAGE => 'en-gb,en;q=0.8',
);

# Test new() error conditions
throws_ok {
	CGI::Lingua::new(undef, { supported => ['en'] });
} qr/use ->new\(\) not ::new\(\) to instantiate/, 'Calling new as function croaks';

throws_ok {
	CGI::Lingua->new();
} qr/^Usage/, 'New without supported languages croaks';

# Test cloning
my $obj1 = CGI::Lingua->new(supported => ['en']);
my $obj2 = $obj1->new(supported => ['fr']);
is_deeply $obj2->{_supported}, ['fr'], 'Cloning merges parameters correctly';

# Test preferred_language and name methods
$ENV{HTTP_ACCEPT_LANGUAGE} = 'en';
my $obj = CGI::Lingua->new(supported => ['en']);
is $obj->preferred_language, 'English', 'preferred_language works';
is $obj->name, 'English', 'name method works';

# Test sublanguage_code_alpha2
$ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
$obj = CGI::Lingua->new(supported => ['en-gb']);
is $obj->sublanguage_code_alpha2, 'gb', 'sublanguage_code_alpha2 returns correct code';

# Test country method with various IPs
$ENV{REMOTE_ADDR} = '8.8.8.8'; # Google DNS
$obj = CGI::Lingua->new(supported => ['en']);
like $obj->country, qr/^[a-z]{2}$/, 'Country returns valid code for public IP';

$obj = CGI::Lingua->new(supported => ['en-gb']);
$ENV{REMOTE_ADDR} = '192.168.1.1';
is $obj->country, undef, 'Country returns undef for private IP';

$ENV{REMOTE_ADDR} = '::1';
is $obj->country, undef, 'Country returns undef for IPv6 loopback';

# Test locale and time_zone methods
$ENV{REMOTE_ADDR} = '8.8.8.8';
$obj = CGI::Lingua->new(supported => ['en']);
isa_ok $obj->locale, 'Locale::Object::Country', 'Locale returns country object';
like $obj->time_zone, qr/.+/, 'Time zone returns string';

# Test DESTROY method
{
	my $cache = CHI->new(driver => 'Memory', global => 1);
	my $obj = CGI::Lingua->new(supported => ['en'], cache => $cache);
	$ENV{REMOTE_ADDR} = '192.168.1.1';
}
pass 'DESTROY called without errors';

# Test with a mock logger
my $log_message;
Test::Mockingbird::mock('Log::Abstraction', 'warn', sub { $log_message = $_[1]->[0]->{'warning'} });
$obj = CGI::Lingua->new(supported_languages => ['en'], logger => new_ok('Log::Abstraction'));
$obj->_warn({ warning => 'Test warning' });
like($log_message, qr/Test warning/, 'Logger received warning');
Test::Mockingbird::unmock('Log::Abstraction', 'error');

# Test _info and _notice methods
$obj->_info('Test info');
$obj->_notice('Test notice');
pass('Info and notice methods called without errors');

done_testing();
