# $Id: ae2.pl,v 1.2 2009-08-06 14:00:36 root Exp $
# An echo client-server benchmark.

use warnings;
use strict;

use Time::HiRes qw(time);
use AnyEvent;
use AnyEvent::Impl::Perl;
use AnyEvent::Socket;

my $CYCLES = 500;
my $port   = 11212;

tcp_server undef, $port, sub {
   my ($fh) = @_
      or die "tcp_server: $!";

   my $hdl = new AnyEvent::Handle fh => $fh;

   $hdl->push_read (line => sub {
      $hdl->push_write ("$_[1]\n");
      undef $hdl;
   });
};

my $t = time;

for my $connections (1..$CYCLES) {
   my $cv = AE::cv;

   tcp_connect "127.0.0.1", $port, sub {
      my ($fh) = @_
         or die "tcp_connect: $!";

      my $hdl = new AnyEvent::Handle fh => $fh;

      $hdl->push_write ("can write $connections\n");
      $hdl->push_read (line => sub {
         undef $hdl;
         $cv->send;
      });
   };

   $cv->recv;
};

$t = time - $t;
printf "%.3f sec\n", $t;
exit;
