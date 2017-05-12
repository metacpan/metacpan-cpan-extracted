#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use Encode;
my $ua = LWP::UserAgent->new();
print "REQUEST: =============\n";
my $message = <<SOAP;
<Envelope xmlns="http://www.w3.org/2003/05/soap-envelope">
    <Body>World</Body>
</Envelope>
SOAP
my $request = HTTP::Request->new('POST','http://localhost:3000/ws/hello');
$request->content_type('application/soap+xml');
$request->content_encoding('utf8');
$request->content(encode_utf8($message));
my $response = $ua->request($request);
print "RESPONSE: ============\n";
print $response->content;
print "======================\n";

__END__

$message = <<SOAP;
<Envelope xmlns="http://www.w3.org/2003/05/soap-envelope">
    <Body><hello>World</hello></Body>
</Envelope>
SOAP
$request = HTTP::Request->new('POST','http://localhost:3000/ws2');
$request->content_type('application/soap+xml');
$request->content_encoding('utf8');
$request->content(encode_utf8($message));
$response = $ua->request($request);
print "MENSAGEM 2============\n";
print $response->content;
print "======================\n";
