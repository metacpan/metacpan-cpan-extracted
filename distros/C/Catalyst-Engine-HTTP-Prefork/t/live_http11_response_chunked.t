#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 3;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use Data::Dump qw(dump);
use IO::Select;
use IO::Socket qw(:crlf);
use IO::Socket::INET;
use HTTP::Response;
use URI;

{
    my $server = URI->new( $ENV{CATALYST_SERVER} || 'http://localhost' );
    my $base   = $server->host . ':' . $server->port;
    
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $server->host,
        PeerPort  => $server->port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Timeout   => 2,
    ) or die "Cannot connect to $server";
    
    # Send request
    syswrite $sock, construct_request( "http://$base/streaming" );
    
    # Read all responses into one big buffer
    my $buf;
    my $sel = IO::Select->new($sock);
    while ( $sel->can_read(1) ) {
        my $n = sysread $sock, my $buf2, 64 * 1024;
        last unless $n;
        $buf .= $buf2;
    }
    
    my $response = HTTP::Response->parse($buf);
    
    is( $response->code, 200, 'Response ok' );
    is( $response->header('Transfer-Encoding'), 'chunked', 'Transfer-Encoding header chunked' );
    
    my $expect = "4\r\nfoo\n\r\n4\r\nbar\n\r\n4\r\nbaz\n\r\n0\r\n\r\n";
    
    is( $response->content, $expect, 'Chunked content ok' );
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