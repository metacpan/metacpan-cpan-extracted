#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;
use Test::Carp;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::ACL');
	use_ok('CGI::Lingua');
}

UNDEF: {
	$ENV{'CONTENT_LENGTH'}  = undef;
	$ENV{'CONTEXT_DOCUMENT_ROOT'} = '/home/hornenj/concert-bands.co.uk';
	$ENV{'CONTEXT_PREFIX'}  = undef;
	$ENV{'DH_USER'}         = 'hornenj';
	$ENV{'DOCUMENT_ROOT'}   = '/home/hornenj/concert-bands.co.uk';
	$ENV{'FCGI_ROLE'}       = 'RESPONDER';
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'HTTPS'}           = 'on';
	$ENV{'HTTP_ACCEPT'}     = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9';
	$ENV{'HTTP_ACCEPT_ENCODING'} = 'gzip';
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en;q=0.9,en-US;q=0.7';
	$ENV{'HTTP_CACHE_CONTROL'} = 'max-age=0';
	$ENV{'HTTP_CDN_LOOP'}   = 'cloudflare; subreqs=1';
	$ENV{'HTTP_CF_CONNECTING_IP'} = '2a06:98c0:3600::103';
	$ENV{'HTTP_CF_EW_VIA'}  = 15;
	$ENV{'HTTP_CF_RAY'}     = '6169524d41a04257-PDX';
	$ENV{'HTTP_CF_REQUEST_ID'} = '07d5b1c44d00004257d584e000000001';
	$ENV{'HTTP_CF_VISITOR'} = '{"scheme":"https"}';
	$ENV{'HTTP_CF_WORKER'}  = 'keywordsur.fr';
	$ENV{'HTTP_CONNECTION'} = 'close';
	$ENV{'HTTP_HOST'}       = 'www.concert-bands.co.uk';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.7 Safari/537.36';
	$ENV{'HTTP_X_FORWARDED_PROTO'} = 'https';
	$ENV{'PATH'}            = '/bin:/usr/bin:/sbin:/usr/sbin';
	$ENV{'QUERY_STRING'}    = 'page=by_location&entry=The%20Yorkshire%20Military%20Band&country=United%20Kingdom';
	# $ENV{'REMOTE_ADDR'}     = '2a06:98c0:3600::103';
	$ENV{'REMOTE_ADDR'} = '87.226.159.0';	# RT
	$ENV{'REMOTE_PORT'}     = 47008;
	$ENV{'REQUEST_METHOD'}  = 'GET';
	$ENV{'REQUEST_SCHEME'}  = 'https';
	$ENV{'REQUEST_URI'}     = '/cgi-bin/page.fcgi?page=by_location&entry=The%20Yorkshire%20Military%20Band&country=United%20Kingdom';
	$ENV{'SCRIPT_FILENAME'} = '/home/hornenj/concert-bands.co.uk/cgi-bin/page.fcgi';
	$ENV{'SCRIPT_NAME'}     = '/cgi-bin/page.fcgi';
	$ENV{'SCRIPT_URI'}      = 'https://www.concert-bands.co.uk/cgi-bin/page.fcgi';
	$ENV{'SCRIPT_URL'}      = '/cgi-bin/page.fcgi';
	$ENV{'SERVER_ADDR'}     = '173.236.242.55';
	$ENV{'SERVER_ADMIN'}    = 'webmaster@concert-bands.co.uk';
	$ENV{'SERVER_NAME'}     = 'www.concert-bands.co.uk';
	$ENV{'SERVER_PORT'}     = 443;
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	$ENV{'SERVER_SIGNATURE'} = undef;
	$ENV{'SERVER_SOFTWARE'} = 'Apache';
	$ENV{'UNIQUE_ID'}       = 'YA1WML0-VEs06KR1KzyVCQAAAEE';
	$ENV{'ds_id_30808457'}  = undef;
	$ENV{'dsid'}            = 30808457;

	my @blacklist_country_list = (
		'BY', 'MD', 'RU', 'CN', 'BR', 'UY', 'TR', 'MA', 'VE', 'SA', 'CY',
		'CO', 'MX', 'IN', 'RS', 'PK', 'UA', 'XH'
	);

	my $acl = CGI::ACL->new()->deny_country(country => \@blacklist_country_list)->allow_ip('131.161.0.0/16')->allow_ip('127.0.0.1');

	ok($acl->all_denied(new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));
}
