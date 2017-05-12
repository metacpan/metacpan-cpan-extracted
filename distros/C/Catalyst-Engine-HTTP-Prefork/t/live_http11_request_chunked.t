#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 5;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use Data::Dump qw(dump);
use HTTP::Request;

{
    my $creq;
    my $expected = {
        one => 'foo',
        two => 'bar',
    };
    
    my $params   = 'one=foo&two=bar';
    my $interval = int( length($params) / 4 );
    my $offset   = 0;
    
    my $request = HTTP::Request->new( POST => 'http://localhost/dump/request' );
    $request->content_type( 'application/x-www-form-urlencoded' );
    
    # This returns a bit of $params each time, LWP will make it chunked
    # The content will become this:
    # 3\r\none\r\n3\r\n=fo\r\n3\r\no&t\r\n3\r\nwo=\r\n3\r\nbar\r\n0\r\n\r\n
    $request->content( sub {
        return if $offset >= length($params);
        my $chunk = substr $params, $offset, $interval;
        $offset += $interval;
        return $chunk;
    } );
    
    ok( my $response = request($request), 'Chunked request' );
    
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    is( $creq->method, 'POST', 'Request method is POST' );
    is( $creq->header('Transfer-Encoding'), 'chunked', 'Transfer-Encoding header is chunked' );
    is_deeply( $creq->{parameters}, $expected, 'Parameters ok' );
}

