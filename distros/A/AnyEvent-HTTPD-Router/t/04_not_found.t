#!perl
use lib 't/lib';
use Test::More;
use common::sense;
use AnyEvent::HTTP qw/http_request/;
use AnyEvent::HTTPD::Router;

my $h = AnyEvent::HTTPD::Router->new();
$h->reg_routes(
    GET => '/foo' => sub {
        my ( $httpd, $req ) = @_;
        $req->respond( [ 200, 'ok', {}, 'GET OK' ] );
        $h->stop_request;
    },
);
$h->reg_cb(
    'no_route_found' => sub {
        my ( $httpd, $req ) = @_;
        $req->respond( [ 404, 'not found', {}, '' ] );
        $h->stop_request;
    }
);

my $c = AnyEvent->condvar;
http_request(
    GET => sprintf( "http://%s:%d/foo", '127.0.0.1', $h->port ),
    sub {
        my ( $body, $hdr ) = @_;
        ok( $hdr->{'Status'} == 200, "resp GET 200 Not Found" )
            or diag explain $hdr;
        ok( $body eq 'GET OK', 'resp GET body OK' )
            or diag explain $body;
        $c->send;
    }
);
$c->recv;

$c = AnyEvent->condvar();
http_request(
    GET => sprintf( "http://%s:%d/bar", '127.0.0.1', $h->port ),
    sub {
        my ( $body, $hdr ) = @_;
        ok( $hdr->{'Status'} == 404, "resp GET 404 Not Found" )
            or diag explain $hdr;
        $c->send;
    }
);
$c->recv;

done_testing();
