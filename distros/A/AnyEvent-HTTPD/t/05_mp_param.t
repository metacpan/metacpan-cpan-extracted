#!perl
use common::sense;
use Test::More tests => 5;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTPD;
use AnyEvent::Socket;

my $c = AnyEvent->condvar;

my $h = AnyEvent::HTTPD->new;

my %params;

$h->reg_cb (
   '/test' => sub {
      my ($httpd, $req) = @_;
      (%params) = $req->vars;

      $req->respond ({
         content => ['text/plain', "Test response"]
      });
   },
);

my $hdl;
my $buf;
tcp_connect '127.0.0.1', $h->port, sub {
   my ($fh) = @_
      or die "couldn't connect: $!";

   $hdl =
      AnyEvent::Handle->new (
         fh => $fh,
         on_read => sub { $hdl->rbuf = '' });

   my $cont =
      "--AaB03x\015\012Content-Disposition: form-data; name=\"submit-name\"\015\012"
      . "\015\012Larry\015\012--AaB03x\015\012Content-Disposition: form-data; name=\"files\"; filename=\"file1.txt\"\015\012Content-Type: text/plain\015\012\015\012Test\015\012Test2\015\012"
      . "--AaB03x\015\012Content-Disposition: form-data; name=\"files2\"; filename=\"file2.txt\"\015\012Content-Type: text/plain\015\012\015\012Test 2\015\012Test2\015\012"
      . "--AaB03x\015\012Content-Disposition: form-data; name=\"files3\";\015\012Content-Type: multipart/mixed, boundary=BbC04y\015\012\015\012"
        . "--BbC04y\015\012Content-disposition: attachment; filename=\"fileX1.txt\"\015\012Content-Type: text/plain\015\012\015\012"
           . "BLABLABLA\015\012"
        . "--BbC04y\015\012Content-disposition: attachment; filename=\"fileX2.xml\"\015\012Content-type: image/gif\015\012\015\012"
           . "XXXXXXXXXXXXXXXXXXXX\015\012"
        ."--BbC04y--\015\012\015\012"
      . "--AaB03x--\015\012";

   $hdl->push_read (line => sub { $c->send });
   $hdl->push_write (
      "POST\040http://localhost:19090/test\040HTTP/1.0\015\012"
      . "Content-Type: multipart/form-data; boundary=AaB03x\015\012"
      . "Content-Length: " . length ($cont) . "\015\012\015\012$cont"

   );
};

$c->recv;

is ($params{'submit-name'}, "Larry", "submit name");
is ($params{files}, "Test\015\012Test2", "files 1");
is ($params{files2}, "Test 2\015\012Test2", "files 2");
is ($params{files3}->[0], "BLABLABLA", "files 3.1");
is ($params{files3}->[1], "XXXXXXXXXXXXXXXXXXXX", "files 3.2");
