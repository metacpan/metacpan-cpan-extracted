use utf8;
use strict;
use warnings;
use Test::More tests => 2;
use AnyEvent;

use AnyEvent::HTTP::ScopedClient;

my $cv   = AE::cv;
my $http = AnyEvent::HTTP::ScopedClient->new('http://www.naver.com/');

$cv->begin;
$http->header( { 'Accept' => '*/*' } )->get(
    sub {
        my ( $body, $hdr ) = @_;
        diag("$hdr->{Status}: $hdr->{Reason}") if $hdr->{Status} !~ /^2/;
        is( $hdr->{Status}, 200, 'GET request' );
        $cv->end;
    }
);

$cv->begin;
$http->post(
    { foo => 'bar', bar => 'baz', baz => '유니코드' },
    sub {
        my ( $body, $hdr ) = @_;
        diag("$hdr->{Status}: $hdr->{Reason}") if $hdr->{Status} !~ /^2/;
        is( $hdr->{Status}, 200, 'POST request' );
        $cv->end;
    }
);

$cv->recv;
