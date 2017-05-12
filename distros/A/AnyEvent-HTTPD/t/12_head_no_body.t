#!perl
use common::sense;
use Test::More tests => 1;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTPD;
use AnyEvent::Socket;

my $h = AnyEvent::HTTPD->new;

$h->reg_cb (
   '/test' => sub {
      my ($httpd, $req) = @_;
      $req->respond ({ content => ['text/plain', "31337"] });
   },
);

my $c = AnyEvent::HTTPD::Util::test_connect ('127.0.0.1', $h->port,
            "HEAD\040http://localhost:19090/test\040HTTP/1.0\015\012\015\012");
my $buf = $c->recv;

ok ($buf !~ /31337/, "no body received");
