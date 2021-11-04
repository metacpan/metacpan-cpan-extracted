#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw(:all);
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();

my $req = HTTP::Request->new(POST => 'https://localhost/cgi-bin/info.pl');
$req->header('content-type' => 'application/json');
$req->content('{ "first": "Nigel", "last": "Horne" }');

my $resp = $ua->request($req);
if($resp->is_success()) {
	print "Reply:\n\t", $resp->decoded_content, "\n";
} else {
	print STDERR $resp->code(), "\n", $resp->message(), "\n";
}
