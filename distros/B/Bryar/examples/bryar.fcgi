#!/usr/bin/perl
#
# This program can be run with a command like this to start a long-lived
# FastCGI bryar daemon:
#
# env - PATH="/usr/local/bin:/usr/bin:/bin" \
# spawn-fcgi \
#	  -u md -g md \
#     -f /var/www/blog/bin/bryar.fcgi \
#	  -s /var/run/bryar/bryar.socket \
#     -P /var/run/bryar/bryar-fcgi.pid
#
# This is an example configuration for lighttpd:
#
# $HTTP["host"] == "blog.example.org" {
#   fastcgi.server = (
#     "/fastcgi/bryar.cgi" => ((
#       "socket"          => "/var/run/bryar/bryar.socket",
#       "check-local"     => "disable",
#     ))
#   )
#
#   $HTTP["url"] =~ "^/data/" { url.access-deny = ("") }
#
#   url.rewrite-once += (
#     "^/+([a-z]+/)?(|id_[0-9]+|before_[0-9]+|200[4-9]/.*)(\?.*)?$"
#                                 => "/fastcgi/bryar.cgi/$1$2$3",
#   )
# }

use warnings;
use strict;

use Bryar;
use CGI::Fast qw(-compile);
use Cache::FileCache;

my $cache = new Cache::FileCache({
	cache_root		=> '/tmp/bryar/',
	cache_depth		=> 0,
});

my $bryar = Bryar->new(
	datadir		=> '/var/www/blog/data',
	renderer	=> 'Bryar::Renderer::TT',
	frontend	=> 'Bryar::Frontend::FastCGI',
	cache		=> $cache,
);

while (my $q = new CGI::Fast) {
	$bryar->config->frontend->fastcgi_request($q);
	eval { $bryar->go };
	print STDERR "$@\n" if $@;
}

