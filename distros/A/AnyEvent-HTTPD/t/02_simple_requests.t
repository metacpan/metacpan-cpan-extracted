#!perl
use common::sense;
use Test::More tests => 8;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTPD;
use AnyEvent::Socket;

my $c = AnyEvent->condvar;

my $h = AnyEvent::HTTPD->new;

my $req_url;
my $req_hdr;

my ($H, $P);

$h->reg_cb (
   '/test' => sub {
      my ($httpd, $req) = @_;
      $req_hdr = $req->headers->{'content-type'};
      $req->respond ({
         content => [
            'text/plain',
            "Test response\0"
            . $req->client_host . "\0"
            . $req->client_port
         ]
      });
   },
   client_connected => sub {
      my ($httpd, $h, $p) = @_;
      ok ($h ne '', "got client host");
      ok ($p ne '', "got client port");
      ($H, $P) = ($h, $p);
   },
   client_disconnected => sub {
      my ($httpd, $h, $p) = @_;
      is ($h, $H, "got client host disconnect");
      is ($p, $P, "got client port disconnect");
   }
);

my $hdl;
my $buf;
tcp_connect '127.0.0.1', $h->port, sub {
   my ($fh) = @_
      or die "couldn't connect: $!";

   $hdl =
      AnyEvent::Handle->new (
         fh => $fh, on_eof => sub { $c->send ($buf) },
         on_read => sub {
            $buf .= $hdl->rbuf;
            $hdl->rbuf = '';
         });
   $hdl->push_write (
      "GET\040http://localhost:19090/test\040HTTP/1.0\015\012Content-Length:\015\012 10\015\012Content-Type: text/html;\015\012 charSet = \"ISO-8859-1\"; Foo=1\015\012\015\012ABC1234567"
   );
};

my $r = $c->recv;

my ($tr, $host, $port) = split /\0/, $r;

ok ($tr =~ /Test response/m, 'test response ok');
ok ($req_hdr =~ /Foo/, 'test header ok');
ok ($host ne '', 'got a client host: ' . $host);
ok ($port ne '', 'got a client port: ' . $port);
