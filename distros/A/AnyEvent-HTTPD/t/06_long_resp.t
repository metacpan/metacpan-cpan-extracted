#!perl
use common::sense;
use Test::More tests => 2;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTPD;
use AnyEvent::Socket;

my $h = AnyEvent::HTTPD->new;

my $SEND = "ELMEXBLABLA1235869302893095934";#"ABCDEF" x 1024;
my $SENT = $SEND;

$h->reg_cb (
   '/test' => sub {
      my ($httpd, $req) = @_;
      $req->respond ({
         content => ['text/plain', sub {
            my ($data_cb) = @_;
            return unless $data_cb;
            $data_cb->(substr $SENT, 0, 10, '');
         }]
      });
   },
);

my $c = AnyEvent::HTTPD::Util::test_connect ('127.0.0.1', $h->port,
           "GET\040http://localhost:19090/test\040HTTP/1.0\015\012\015\012");
my $buf = $c->recv;

$buf =~ s/^.*?\015?\012\015?\012//s;
ok (length ($buf) == length ($SEND), 'sent all data');
ok (length ($SENT) == 0, 'send buf empty');
