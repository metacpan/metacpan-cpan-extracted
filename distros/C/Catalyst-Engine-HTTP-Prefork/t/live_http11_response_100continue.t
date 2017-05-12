#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 10;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use Data::Dump qw(dump);
use IO::Select;
use IO::Socket qw(:crlf);
use IO::Socket::INET;
use HTTP::Response;
use URI;

my $server = URI->new( $ENV{CATALYST_SERVER} || 'http://localhost' );
my $base   = $server->host . ':' . $server->port;

# Test 100-continue with HTTP/1.1 request
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/dump/request", '1.1', '100-continue' );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    
    like( $buf, qr{^HTTP/1.1 100 Continue}, '100 Continue ok' );
    
    # Continue sending a POST body
    syswrite $sock, 'one=foo&two=bar';
    
    # Read/parse response
    sysread $sock, $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->code, 200, 'Response ok' );
    
    my $creq;
    my $expected = {
        one => 'foo',
        two => 'bar',
    };
    
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    is( $creq->method, 'POST', 'Request method is POST' );
    is_deeply( $creq->{parameters}, $expected, 'Parameters ok' );
}

# Test invalid Expect header
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/dump/request", '1.1', '200-bleh' );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    
    like( $buf, qr{^HTTP/1.1 417}, 'Invalid expect returned 417' );    
}

# Test Expect header with HTTP/1.0
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/dump/request", '1.0', '100-continue' );
    
    # Continue sending a POST body
    syswrite $sock, 'one=foo&two=bar';
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->code, 200, 'Response ok' );    
    
    my $creq;
    my $expected = {
        one => 'foo',
        two => 'bar',
    };
    
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    is( $creq->method, 'POST', 'Request method is POST' );
    is_deeply( $creq->{parameters}, $expected, 'Parameters ok' );
}

sub construct_request {
    my ( $url, $protocol, $expect ) = @_;
    
    my $uri = URI->new($url);
    my $req 
        = 'POST ' . $uri->path_query . ' HTTP/' . $protocol . $CRLF
        . 'Host: ' . $uri->host . ':' . $uri->port . $CRLF
        . 'Content-Type: application/x-www-form-urlencoded' . $CRLF
        . 'Content-Length: 15' . $CRLF
        . 'Expect: ' . $expect . $CRLF . $CRLF;
    
    return $req;
}