#!perl
use common::sense;
use Test::More tests => 8;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTPD;

my $h = AnyEvent::HTTPD->new (port => 19090);

$h->reg_cb (
   '/header-unset' => sub {
      my ($httpd, $req) = @_;
      $req->respond (
         [200, 'OK', {
            'Cache-Control' => undef,
            'Expires' => undef,
            'Content-Length' => undef,
         }, "Test response"]);
   },
   '/header-override-lowercase' => sub {
      my ($httpd, $req) = @_;
      $req->respond (
         [200, 'OK', {
            'cache-control' => "nonsensical",
         }, "Test response"]);
   },
   '/header-override-uppercase' => sub {
      my ($httpd, $req) = @_;
      $req->respond (
         [200, 'OK', {
            'CACHE-CONTROL' => "nonsensical",
         }, "Test response"]);
   },
);


my $c1 = AnyEvent::HTTPD::Util::test_connect ('127.0.0.1', $h->port,
            "GET\040/header-unset\040HTTP/1.0\015\012Connection: Keep-Alive\015\012\015\012");
my $c2 = AnyEvent::HTTPD::Util::test_connect ('127.0.0.1', $h->port,
            "GET\040/header-override-lowercase\040HTTP/1.0\015\012\015\012");
my $c3 = AnyEvent::HTTPD::Util::test_connect ('127.0.0.1', $h->port,
            "GET\040/header-override-uppercase\040HTTP/1.0\015\012\015\012");
my $r1 = $c1->recv;
my $r2 = $c2->recv;
my $r3 = $c3->recv;

unlike ($r1, qr/^expires:/im,        "Can unset Expires header");
unlike ($r1, qr/^cache-control:/im,  "Can unset Cache-Control header");
unlike ($r1, qr/^content-length:/im, "Can unset Content-Length header");
unlike ($r1, qr/^connection:\s*close$/im,
        "Unsetting Content-Length implies no keep-alive");

like ($r2, qr/^cache-control:\s*nonsensical/im,
      "Cache-Control set with lowercase gets through");
unlike ($r2, qr/^cache-control:\s*max-age/im,
        "Cache-Control set with lowercase removes default header");

like ($r3, qr/^cache-control:\s*nonsensical/im,
      "Cache-Control set with uppercase gets through");
unlike ($r3, qr/^cache-control:\s*max-age/im,
        "Cache-Control set with uppercase removes default header");

