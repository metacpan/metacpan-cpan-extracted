#!/usr/bin/env perl
#
# Run with:
# starman -l 127.0.0.1:5008 --workers 1 httpd/cgi-bin/generic.cart.psgi &
# or, for more debug output:
# plackup -l 127.0.0.1:5008 httpd/cgi-bin/generic.cart.psgi &

use strict;
use warnings;

use CGI::Application::Dispatch::PSGI;

use Plack::Builder;

# ---------------------

my($app) = CGI::Application::Dispatch -> as_psgi
(
	prefix => 'Business::Cart::Generic::Controller',
	table  =>
	[
	''              => {app => 'Initialize', rm => 'display'},
	':app'          => {rm => 'display'},
	':app/:rm/:id?' => {},
	],
);

builder
{
	enable "ContentLength";
	enable "Static",
	path => qr!^/(assets|favicon|yui)!,
	root => '/dev/shm/html';
	$app;
};
