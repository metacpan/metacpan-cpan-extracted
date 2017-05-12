#!/usr/bin/env perl
#
# Run with:
# starman -l 127.0.0.1:5003 --workers 1 httpd/cgi-bin/office/contacts.psgi &
# or, for more debug output:
# plackup -l 127.0.0.1:5003 httpd/cgi-bin/office/contacts.psgi &

use strict;
use warnings;

use CGI::Snapp::Dispatch;

use Plack::Builder;

# ---------------------

my($app) = CGI::Snapp::Dispatch -> new -> as_psgi
(
	prefix => 'App::Office::Contacts::Controller',
	table  =>
	[
	''              => {app => 'Initialize', rm => 'display'},
	':app'          => {rm => 'display'},
	':app/:rm/:id?' => {},
	],
);

builder
{
	enable 'ContentLength';
	enable 'Static',
	path => qr!^/(assets|favicon)!,
	root => '/dev/shm/html';
	$app;
};
