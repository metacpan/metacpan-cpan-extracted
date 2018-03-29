#!perl -wT

use strict;
use warnings;
use Test::Most tests => 25;
use Test::NoWarnings;
use Sys::Hostname;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('CGI::Info');
}

HOSTNAMES: {
        delete $ENV{'HTTP_HOST'};
        delete $ENV{'SERVER_NAME'};
	$ENV{'SERVER_PORT'} = 80;

	my $i = new_ok('CGI::Info' => [ logger => MyLogger->new() ]);

	my $hostname = hostname;

	ok($i->host_name() eq $hostname);
	ok($i->cgi_host_url() eq "http://$hostname");

	# Check rereading returns the same value
	ok($i->host_name() eq $hostname);

	if($i->host_name() =~ /^www\.(.+)/) {
		ok($i->domain_name() eq $1);
	} else {
		ok($i->domain_name() eq $hostname);
	}

	$ENV{'HTTP_HOST'} = 'www.example.com';
	$i = $i->new();	# Test creating a new object from an existing object
	ok($i->domain_name() eq 'example.com');
	ok($i->host_name() eq 'www.example.com');

	# Dots at the end should be ignored
	$ENV{'HTTP_HOST'} = 'www.example.com.';
	$i = new_ok('CGI::Info');
	ok($i->host_name() eq 'www.example.com');
	ok($i->domain_name() eq 'example.com');

	# Check rereading returns the same value
	ok($i->domain_name() eq 'example.com');

        delete $ENV{'HTTP_HOST'};
	delete $ENV{'SCRIPT_URI'};
	$ENV{'SERVER_NAME'} = 'www.bandsman.co.uk';

	$i = new_ok('CGI::Info' => [ logger => MyLogger->new() ]);
	ok($i->cgi_host_url() eq 'http://www.bandsman.co.uk');
	ok($i->host_name() eq 'www.bandsman.co.uk');
	# Check calling twice return path
	ok($i->cgi_host_url() eq 'http://www.bandsman.co.uk');

	$ENV{'SERVER_NAME'} = 'www.bandsman.co.uk';
	$ENV{'SERVER_PORT'} = 443;

	$i = new_ok('CGI::Info');
	ok($i->cgi_host_url() eq 'https://www.bandsman.co.uk');
	ok($i->host_name() eq 'www.bandsman.co.uk');
	# Check calling twice return path
	ok($i->cgi_host_url() eq 'https://www.bandsman.co.uk');

	$ENV{'SERVER_PORT'} = 80;

	$i = new_ok('CGI::Info' => [ logger => MyLogger->new() ]);
	ok($i->cgi_host_url() eq 'http://www.bandsman.co.uk');
	ok($i->host_name() eq 'www.bandsman.co.uk');
	# Check calling twice return path
	ok($i->cgi_host_url() eq 'http://www.bandsman.co.uk');
}
