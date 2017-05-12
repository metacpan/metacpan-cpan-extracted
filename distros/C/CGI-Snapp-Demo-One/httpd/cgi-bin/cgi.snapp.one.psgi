#!/usr/bin/env perl
#
# Run with:
# starman -l 127.0.0.1:5171 --workers 1 httpd/cgi-bin/cgi.snapp.one.psgi &
# or, for more debug output:
# plackup -l 127.0.0.1:5171 httpd/cgi-bin/cgi.snapp.one.psgi &

use strict;
use warnings;

use CGI;
use CGI::Emulate::PSGI;
use CGI::Snapp::Demo::One;

use Plack::Builder;

# ---------------------

my($app) = CGI::Emulate::PSGI -> handler
(
sub
{
	CGI::initialize_globals();
	my $q = CGI->new;
	CGI::Snapp::Demo::One -> new(QUERY => $q) -> run;
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
