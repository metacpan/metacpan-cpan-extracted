#!/usr/bin/env perl
#
# Run with:
# starman -l 127.0.0.1:5173 --workers 1 httpd/cgi-bin/cgi.snapp.three.psgi &
# or, for more debug output:
# plackup -l 127.0.0.1:5173 httpd/cgi-bin/cgi.snapp.three.psgi &

use strict;
use warnings;

use CGI;
use CGI::Emulate::PSGI;
use CGI::Snapp::Demo::Three;

use Plack::Builder;

# ---------------------

my($app) = CGI::Emulate::PSGI -> handler
(
sub
{
	CGI::initialize_globals();
	my $q = CGI->new;
	CGI::Snapp::Demo::Three -> new(QUERY => $q) -> run;
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
