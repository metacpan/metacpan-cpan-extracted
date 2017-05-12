# $Id: ae0.pl,v 1.2 2009-08-06 14:00:36 root Exp $
# An echo client-server benchmark.

use warnings;
use strict;

use Time::HiRes qw(time);
use AnyEvent;
use AnyEvent::Impl::Perl;
use AnyEvent::Socket;
use IO::Socket::INET;

my $CYCLES = 500;
my $port   = 11212;

my $serv_sock = IO::Socket::INET-> new(
        Listen    => 5,
        LocalPort => $port,
        Proto     => 'tcp',
        ReuseAddr => 1,
);

my $serv_w = AE::io $serv_sock, 0, sub {
   accept my $fh, $serv_sock
      or return;
   sysread $serv_sock, my $buf, 512;
   syswrite $serv_sock, $buf;
};

my $t = time;
my $connections;

sub _make_connection {
   if ($connections++ < $CYCLES) {
      tcp_connect "127.0.0.1", $port, sub {
         my ($fh) = @_
            or die "tcp_connect: $!";
         syswrite $fh, "can write $connections\n";
         my $w; $w = AE::io $fh, 0, sub {
            sysread $fh, my $buf, 512;
            undef $fh;
            undef $w;
            &_make_connection;
         };
      };
   } else {
      $t = time - $t;
      printf "%.3f sec\n", $t;
      exit;
   }
};

_make_connection;
AnyEvent->condvar->recv;

