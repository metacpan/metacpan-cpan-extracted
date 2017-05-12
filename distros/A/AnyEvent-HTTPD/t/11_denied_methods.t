#!perl
use common::sense;
use Test::More tests => 13;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::HTTPD qw/http_request/;

my ($H, $P);

# allow options, disallow POST
my $c = AnyEvent->condvar;
my $h = AnyEvent::HTTPD->new( allowed_methods => [qw/GET HEAD OPTIONS/] );

$h->reg_cb (
   '' => sub {
      my ($httpd, $req) = @_;
      ok(scalar (grep { $req->method eq $_ } qw/GET HEAD OPTIONS/) == 1, "req " . $req->method );
      if ($req->method eq 'POST')
      {
        ok(0, "got disallowed request");
        $req->respond({ content => ['text/plain', $req->method . "NOT OK" ]});
      }
      else
      {
        ok(1, "got allowed request");
        $req->respond({ content => ['text/plain', $req->method . " OK" ]});
      }
   },
   client_connected => sub {
      my ($httpd, $h, $p) = @_;
      ($H, $P) = ($h, $p);
   },
);

is_deeply( $h->allowed_methods, [qw/GET HEAD OPTIONS/], 'allowed_methods()' );

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
    ok($hdr->{'Status'} == 501, "resp POST 501")
      or diag explain $hdr;
    ok($hdr->{'Reason'} == 'not implemented', 'resp POST reason')
      or diag explain $hdr;
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
    ok($hdr->{'Status'} == 200, "resp OPTIONS OK")
      or diag explain $hdr;
    $c->send;
  }
);

$c->recv;

done_testing();

