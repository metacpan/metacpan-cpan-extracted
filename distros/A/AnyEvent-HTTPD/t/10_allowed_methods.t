#!perl
use common::sense;
use Test::More tests => 12;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::HTTPD qw/http_request/;

my ($H, $P);

# make sure the default is GET HEAD POST
my $c = AnyEvent->condvar;
my $h = AnyEvent::HTTPD->new;

$h->reg_cb (
   '' => sub {
      my ($httpd, $req) = @_;
      ok(scalar (grep { $req->method eq $_ } qw/GET HEAD POST/) == 1, "req " . $req->method );
      if ($req->method eq 'POST')
      {
        ok($req->content eq 'hello world', "req POST body");
      }
      $req->respond({ content => ['text/plain', $req->method . " OK" ]});
   },
   client_connected => sub {
      my ($httpd, $h, $p) = @_;
      ($H, $P) = ($h, $p);
   },
);

is_deeply( $h->allowed_methods, [qw/GET HEAD POST/], 'allowed_methods()' );

http_request(
  GET => sprintf("http://%s:%d/foo", '127.0.0.1', $h->port),
  sub {
    my ($body, $hdr) = @_;
    ok($hdr->{'Status'} == 200, "resp GET 200 OK")
      or diag explain $hdr;
    ok($body eq 'GET OK', 'resp GET body OK')
      or diag explain $body;
    $c->send;
  }
);

$c->recv;
$c = AnyEvent->condvar;

http_request(
  POST => sprintf("http://%s:%d/foo", '127.0.0.1', $h->port),
  body => 'hello world',
  sub {
    my ($body, $hdr) = @_;
    ok($hdr->{'Status'} == 200, "resp POST 200 OK")
      or diag explain $hdr;
    ok($body eq 'POST OK', 'resp POST body OK')
      or diag explain $body;
    $c->send;
  }
);

$c->recv;
$c = AnyEvent->condvar;

http_request(
  HEAD => sprintf("http://%s:%d/foo", '127.0.0.1', $h->port),
  sub {
    my ($body, $hdr) = @_;
    ok($hdr->{'Status'} == 200, "resp HEAD 200 OK")
      or diag explain $hdr;
    $c->send;
  }
);

$c->recv;
$c = AnyEvent->condvar;

http_request(
  OPTIONS => sprintf("http://%s:%d/foo", '127.0.0.1', $h->port),
  sub {
    my ($body, $hdr) = @_;
    ok($hdr->{'Status'} == 501, "resp OPTIONS 501")
      or diag explain $hdr;
    ok($hdr->{'Reason'} == 'not implemented', 'resp OPTIONS reason')
      or diag explain $hdr;
    $c->send;
  }
);

$c->recv;

done_testing();

