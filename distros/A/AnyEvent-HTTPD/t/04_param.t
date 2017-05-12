#!perl
use common::sense;
use Test::More tests => 2;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTPD;

my $h = AnyEvent::HTTPD->new (port => 19090);

my $req_q;
my $req_n;

$h->reg_cb (
   '/test' => sub {
      my ($httpd, $req) = @_;
      $req_q = $req->parm ('q');
      $req_n = $req->parm ('n');
      $req->respond ({ content => ['text/plain', "Test response"] });
   },
);


my $c = AnyEvent::HTTPD::Util::test_connect ('127.0.0.1', $h->port,
            "GET\040http://localhost:19090/test?q=%3F%3F&n=%3F2%3F\040HTTP/1.0\015\012\015\012");
$c->recv;

is ($req_q, "??", "parameter q correct");
is ($req_n, "?2?", "parameter n correct");
