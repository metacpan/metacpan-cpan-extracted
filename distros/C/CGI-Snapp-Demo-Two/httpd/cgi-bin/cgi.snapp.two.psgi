#!/usr/bin/env perl
#
# Run with:
# starman -l 127.0.0.1:5172 --workers 1 httpd/cgi-bin/cgi.snapp.two.psgi &
# or, for more debug output:
# plackup -l 127.0.0.1:5172 httpd/cgi-bin/cgi.snapp.two.psgi &

use strict;
use warnings;

use CGI;
use CGI::Emulate::PSGI;
use CGI::Snapp::Demo::Two;

use Plack::Builder;

# ---------------------

my($app) = CGI::Emulate::PSGI -> handler
(
sub
{
	CGI::initialize_globals();
	my $q = CGI->new;
	CGI::Snapp::Demo::Two -> new(QUERY => $q) -> run;
}
);

builder
{
	enable "ContentLength";
	enable "Static",
	path => qr!^/(assets|favicon|yui)!,
	root => '/dev/shm/html';
	$app;
};
