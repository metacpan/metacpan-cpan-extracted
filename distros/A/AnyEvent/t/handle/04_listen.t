#!/opt/perl/bin/perl

use strict;

use AnyEvent;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }
use AnyEvent::Handle;
use AnyEvent::Socket;

my $lbytes;
my $rbytes;

print "1..2\n";

my $cv = AnyEvent->condvar;

my $hdl;
my $port;

my $w = tcp_server undef, undef,
   sub {
      my ($fh, $host, $port) = @_;

      $hdl = AnyEvent::Handle->new (fh => $fh, on_eof => sub { $cv->broadcast });

      $hdl->push_read (chunk => 6, sub {
         my ($hdl, $data) = @_;

         if ($data eq "TEST\015\012") {
            print "ok 1 - server received client data\n";
         } else {
            print "not ok 1 - server received bad client data\n";
         }

         $hdl->push_write ("BLABLABLA\015\012");
      });
   }, sub {
      $port = $_[2];

      0
   };

my $clhdl; $clhdl = AnyEvent::Handle->new (
   connect => [localhost => $port],
   on_eof => sub { $cv->broadcast },
);

$clhdl->push_write ("TEST\015\012");
$clhdl->push_read (line => sub {
   my ($clhdl, $line) = @_;

   if ($line eq 'BLABLABLA') {
      print "ok 2 - client received response\n";
   } else {
      print "not ok 2 - client received bad response\n";
   }

   $cv->broadcast;
});

$cv->wait;
