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

my $server = URI->new( $ENV{CATALYST_SERVER} || 'http://localhost' );
my $base   = $server->host . ':' . $server->port;

# Test absolute request
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/dump/request", 'foo.bar.com:3000' );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->code, 200, 'Response ok' );
    
    my $creq;    
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    
    like( $creq->base, qr/$base/, 'base uses host from absolute request' );
}

# Test normal request without Host header
{
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "/dump/request" );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->code, 400, 'Invalid response ok' );
}

sub construct_request {
    my ( $url, $host ) = @_;
    
    my $req 
        = 'GET ' . $url . ' HTTP/1.1' . $CRLF;
    
    if ( $host ) {
        $req .= 'Host: foo.bar.com:3000' . $CRLF;
    }
    
    $req .= $CRLF;
    
    return $req;
}