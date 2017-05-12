#!/usr/bin/perl

my $r = shift;
$r->send_http_header('ungulate/moose');
$r->send_cgi_header;

print "blah\n";
