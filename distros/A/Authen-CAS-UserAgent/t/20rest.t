#!/usr/bin/perl

use strict;
use lib substr(__FILE__, 0, rindex(__FILE__, '/'));
require 'MockUserAgent.pl';

use Test::More 'tests' => 10;
use Authen::CAS::UserAgent;
use URI;
use URI::QueryParam;

# settings
my $casServer = URI->new('https://cas.example.com/cas/');
my $username = 'username';
my $password = 'password';
my $service = URI->new('https://www.example.com/test1');
my $ticket;

my $tgt = 'TGT-' . join('', map {chr(rand(26)+65)} (0..19));
my $restLoginUri = URI->new_abs('v1/tickets', $casServer);
my $restTgtUri = URI->new($restLoginUri . '/' . $tgt);

# configure Mock Responses for REST login API
my $loginUri = URI->new_abs('login', $casServer);
$loginUri->query_param('service', $service);
addMockResponses({
	$service  => HTTP::Response->new(302, undef, ['Location' => $loginUri]),
});

# REST TGT api
addMockResponses(sub {
	my ($request) = @_;
	if($request->uri eq $restLoginUri && $request->method eq 'POST') {
		my $params = URI->new('http:');
		$params->query($request->decoded_content);
		if($params->query_param('username') eq $username && $params->query_param('password') eq $password) {
			return HTTP::Response->new(201, undef, ['Location' => $restTgtUri]);
		} else {
			return HTTP::Response->new(400);
		}
	}

	return;
});

# REST ST api
addMockResponses(sub {
	my ($request) = @_;
	if($request->uri eq $restTgtUri && $request->method eq 'POST') {
		my $params = URI->new('http:');
		$params->query($request->decoded_content);
		if($params->query_param('service') eq $service) {
			# generate & return a ticket
			$ticket = 'ST-' . join('', map {chr(rand(26)+65)} (0..19));
			return HTTP::Response->new(200, undef, undef, $ticket);
		} else {
			return HTTP::Response->new(400);
		}
	}

	return;
});

# service w/ ticket
addMockResponses(sub {
	my ($request) = @_;
	my $uri = $request->uri->clone;
	my $reqTicket = $uri->query_param('ticket');
	$uri->query_param_delete('ticket');
	if($service->canonical eq $uri->canonical && $reqTicket) {
		if($ticket eq $reqTicket) {
			return HTTP::Response->new(200, undef, undef, 'success');
		}
		else {
			return HTTP::Response->new(401, undef, undef, 'error');
		}
	}

	return;
});

my $ua = Authen::CAS::UserAgent->new(
	'requests_redirectable' => [],
	'cas_opts' => {
		'server' => $casServer,
		'username' => $username,
		'password' => $password,
		'restful' => 1,
	},
);
my $response;

# valid username & password
$ua->attach_cas_handler(
	'server' => $casServer,
	'username' => $username,
	'password' => $password,
	'restful' => 1,
);
$response = $ua->get($service);
is($response->code, 200);
is($response->decoded_content, 'success');

# invalid username & password
$ua->attach_cas_handler(
	'server' => $casServer,
	'username' => $username,
	'password' => $password . '.invalid',
	'restful' => 1,
);
$response = $ua->get($service);
is($response->code, 302);
is($response->header('Location'), $loginUri);
