#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 10;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use IO::Select;
use IO::Socket qw(:crlf);
use IO::Socket::INET;
use HTTP::Response;
use URI;

{
    my $server = URI->new( $ENV{CATALYST_SERVER} || 'http://localhost' );
    my $base   = $server->host . ':' . $server->port;
    
    my @reqs = (
        "http://$base/dump/request?req=1",
        "http://$base/dump/request?req=2",
        "http://$base/dump/request?req=3",
        "http://$base/dump/request?req=4",
    );
    
    # Make first request normally, we then reuse the keep-alive connection
    # to pipeline the next 3 requests
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( shift @reqs );
    
    # Read/parse response
    sysread $sock, my $buf, 64 * 1024;
    my $response = HTTP::Response->parse($buf);
    
    is( $response->code, 200, 'Response ok' );
    is( $response->header('Connection'), 'keep-alive', 'Keep-alive header ok' );
    
    my $creq;
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    is( $creq->{parameters}->{req}, 1, 'request 1 ok' );
    
    # Send next 3 requests pipelined
    syswrite $sock, construct_request( @reqs );
    
    # Read all responses into one big buffer
    my $pipebuf;
    my $sel = IO::Select->new($sock);
    while ( $sel->can_read(1) ) {
        my $n = sysread $sock, my $buf2, 64 * 1024;
        last unless $n;
        $pipebuf .= $buf2;
    }
    
    my $count = 2;
    for my $resp ( split m{HTTP/1.1 200 OK}, $pipebuf ) {
        next unless $resp;
        
        $resp = 'HTTP/1.1 200 OK' . $resp;
        
        my $response = HTTP::Response->parse($resp);
        
        my $creq;
        ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
        is( $creq->{parameters}->{req}, $count, "request $count ok" );
        
        $count++;
    }
}

sub construct_request {
    my @urls = @_;
    
    my $req;
    
    for my $url ( @urls ) { 
        my $uri = URI->new($url);
        $req 
            .= 'GET ' . $uri->path_query . ' HTTP/1.1' . $CRLF
            .  'Host: ' . $uri->host . ':' . $uri->port . $CRLF . $CRLF;
    }
    
    return $req;
}