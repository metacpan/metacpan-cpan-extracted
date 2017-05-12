#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use Data::Dump qw(dump);
use IO::Select;
use IO::Socket qw(:crlf);
use IO::Socket::INET;
use HTTP::Response;
use URI;

# With LWP it is difficult or impossible to change the Connection header
# or use HTTP/1.0, so manually create some requests

my $server = URI->new( $ENV{CATALYST_SERVER} || 'http://localhost' );
my $base   = $server->host . ':' . $server->port;

# Test normal HTTP/1.1 request, should return Connection: keep-alive
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/dump/request", '1.1', 'keep-alive' );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->header('Connection'), 'keep-alive', 'HTTP/1.1, keep-alive ok' );
}

# Test HTTP/1.1 with Connection: close, should return Connection: close
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/dump/request", '1.1', 'close' );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->header('Connection'), 'close', 'HTTP/1.1, close ok' );
}

# Test HTTP/1.0 with Connection: Keep-Alive header, should return Connection: keep-alive
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/dump/request", '1.0', 'keep-alive' );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->header('Connection'), 'keep-alive', 'HTTP/1.0, keep-alive ok' );
}

# Test HTTP/1.0 with no Connection header, should return Connection: close
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/dump/request", '1.0', '' );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->header('Connection'), 'close', 'HTTP/1.0, no Connection header ok' );
}

sub construct_request {
    my ( $url, $protocol, $connection ) = @_;
    
    my $uri = URI->new($url);
    my $req 
        = 'GET ' . $uri->path_query . ' HTTP/' . $protocol . $CRLF
        .  'Host: ' . $uri->host . ':' . $uri->port . $CRLF;
        
    if ( $connection ) {
        $req .= "Connection: $connection" . $CRLF;
    }
    
    $req .= $CRLF;
    
    return $req;
}
