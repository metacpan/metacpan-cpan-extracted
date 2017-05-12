#!perl
use common::sense;
use Test::More tests => 1;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTPD;
use AnyEvent::Socket;

my $c = AnyEvent->condvar;

my $h = AnyEvent::HTTPD->new;

my $cnt = 0;

$h->reg_cb (
   '/test' => sub {
      my ($httpd, $req) = @_;
      $cnt++;
      $req->respond ({ content => ['text/plain', "Test response ($cnt)"] });
   },
);

my $hdl;
my $buf;
tcp_connect '127.0.0.1', $h->port, sub {
   my ($fh) = @_
      or die "couldn't connect: $!";

   $hdl =
      AnyEvent::Handle->new (
         fh => $fh, on_eof => sub { $c->send },
         on_read => sub {
            $buf .= $hdl->rbuf;
            $hdl->rbuf = '';
            if ($buf =~ /Test response \(2\)/) {
               $c->send;
            }
         });

   for (1..2) {
      $hdl->push_write (
         "GET\040http://localhost:19090/test\040HTTP/1.0\015\012"
         . "Connection: Keep-Alive\015\012\015\012"
      );
   }
};

$c->recv;

is ($cnt, 2, 'two requests over one connection');
