#!/usr/bin/env perl
#
# Run with:
# starman -l 127.0.0.1:5021 --workers 1 httpd/cgi-bin/cgi/application/demo/dispatch/dispatch.psgi &
# or, for more debug output:
# plackup -l 127.0.0.1:5021 httpd/cgi-bin/cgi/application/demo/dispatch/dispatch.psgi &

use strict;
use warnings;

use CGI::Application::Dispatch::PSGI;

use Plack::Builder;

# ---------------------

my($app) = CGI::Application::Dispatch -> as_psgi
(
	 prefix      => 'CGI::Application::Demo::Dispatch',
	 table       =>
	 [
	  ''         => {app => 'Menu', rm => 'display'},
	  ':app'     => {rm => 'display'},
	  ':app/:rm' => {},
	 ],
);

builder
{
	enable "Plack::Middleware::Static",
	path => qr!^/(assets|favicon|yui)/!,
	root => '/dev/shm/html';
	$app;
};
