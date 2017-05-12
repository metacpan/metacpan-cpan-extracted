#!/usr/bin/env perl
# PODNAME: tcpproxy.pl
# ABSTRACT: Simple TCP proxy for debugging connections

use strict;
use warnings;

use Term::ANSIColor qw( colored );
use AnyEvent::Handle;
use AnyEvent::Socket;
use Carp qw( croak );
use DDC;

sub logmsg {
  print colored($_[0],'yellow')."\n";
}

sub in {
  print colored(' IN ','yellow');
  print colored('[','blue');
  pc($_[0]);
  print colored(']','blue')."\n";
}

sub out {
  print colored('OUT ','yellow');
  print colored('[','blue');
  pc($_[0]);
  print colored(']','blue')."\n";
}

sub create_proxy {
  my ( $port, $remote_host, $remote_port ) = @_;

  my %handles;

  my $ip = '127.0.0.1';

  if ($port =~ /:/) {
    ( $ip, $port ) = split(/:/,$port);
  }

  logmsg("starting proxy on $ip:$port");

  return tcp_server $ip, $port, sub {
    my ( $client_fh, $client_host, $client_port ) = @_;

    logmsg("received connection from $client_host:$client_port");

    my $client_h = AnyEvent::Handle->new(
      fh => $client_fh,
    );

    $handles{$client_h} = $client_h;

    tcp_connect $remote_host, $remote_port, sub {
      unless(@_) {
        logmsg("connection failed: $!");
        $client_h->destroy;
        return;
      }
      my ( $host_fh ) = @_;

      my $host_h = AnyEvent::Handle->new(
        fh => $host_fh,
      );

      $handles{$host_h} = $host_h;

      $client_h->on_read(sub {
        my $buffer      = $client_h->rbuf;
        $client_h->rbuf = '';
        out($buffer);
        $host_h->push_write($buffer);
      });

      $client_h->on_error(sub {
        my ( undef, undef, $msg ) = @_;
        logmsg("transmission error: $msg");
        $client_h->destroy;
        $host_h->destroy;
        delete @handles{$client_h, $host_h};
      });

      $client_h->on_eof(sub {
        logmsg("client closed connection");
        $client_h->destroy;
        $host_h->destroy;
        delete @handles{$client_h, $host_h};
      });

      $host_h->on_read(sub {
        my $buffer    = $host_h->rbuf;
        $host_h->rbuf = '';
        in($buffer);
        $client_h->push_write($buffer);
      });

      $host_h->on_error(sub {
        my ( undef, undef, $msg ) = @_;
        logmsg("transmission error: $msg");
        $host_h->destroy;
        $client_h->destroy;
        delete @handles{$client_h, $host_h};
      });

      $host_h->on_eof(sub {
        logmsg("host closed connection");
        $host_h->destroy;
        $client_h->destroy;
        delete @handles{$client_h, $host_h};
      });
    };
  };
}

unless(@ARGV == 3) {
    print <<"END_USAGE";
usage: $0 [<ip:>localport] [remotehost] [remoteport]

END_USAGE
  exit 0
}

my ( $port, $remote_host, $remote_port ) = @ARGV;

my $cond = AnyEvent->condvar;

my $proxy = create_proxy($port, $remote_host, $remote_port);

$cond->recv;

__END__

=pod

=head1 NAME

tcpproxy.pl - Simple TCP proxy for debugging connections

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  $ tcpproxy.pl 2300 localhost 23
  starting proxy on 127.0.0.1:2300
  received connection from 127.0.0.1:37978
   IN [<ff><fd>[CAN]<ff><fd> <ff><fd>#<ff><fd>']
  OUT [<ff><fb>[CAN]<ff><fb> <ff><fb>#<ff><fb>']
   IN [<ff><fa> [NUL]<ff><f0><ff><fa>#[NUL]<ff><f0><ff><fa>'[NUL]<ff><f0><ff><fa>[CAN][NUL]<ff><f0>]
  OUT [<ff><fa> <00>38400,38400<ff><f0><ff><fa>#<00>localhost:16.0<ff><f0><ff><fa>'<00><00>DISPLAY[NUL]localhost:16.0<ff><f0><ff><fa>[CAN]<00>xterm<ff><f0>]
   IN [<ff><fb>[STX]<ff><fd>[NUL]<ff><fd>[US]<ff><fb>[ENQ]<ff><fd>!]
  OUT [<ff><fd>[STX]<ff><fc>[NUL]<ff><fb>[US]<ff><fa>[US]<00>c<00>v<ff><f0><ff><fd>[ENQ]<ff><fb>!]
   IN [<ff><fb>[NUL]]
  OUT [<ff><fd>[NUL]]
   IN [Debian GNU/Linux 7[CR][LF]]
   IN [bigbird login: ]
  OUT [a]
   IN [a]
  OUT [t]
   IN [t]
  OUT [c]
   IN [c]
  OUT [[CR]<00>]
   IN [[CR][LF]]
   IN [Password: ]
  OUT [a]
  OUT [t]
  OUT [c]
  OUT [[CR]<00>]
   IN [[CR][LF]]
   IN [Last login: Fri Dec  5 01:58:51 CET 2014 from localhost on pts/7[CR][LF]Linux bigbird 3.2.0-4-amd64 #1 SMP Debian 3.2.63-2+deb7u1 x86_64[CR][LF][CR][LF]The programs included with the Debian GNU/Linux system are free software;[CR][LF]the exact distribution terms for each program are described in the[CR][LF]individual files in /usr/share/doc/*/copyright.[CR][LF][CR][LF]Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent[CR][LF]permitted by applicable law.[CR][LF]]
   IN [[ESC]]0;atc@bigbird: ~[BEL]atc@bigbird:~$ ]
  OUT [[ETX]]
   IN [logout[CR][LF]]

=head1 DESCRIPTION

A simple tcpproxy for analyzing traffic between a tcp client and a tcp server.
Cyan colored data is hex value of the char at this position, while red colored
data are the special control sequences at the beginning of the ASCII table.

=head1 SUPPORT

IRC

  Join #vonbienenstock on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-app-tcpproxy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-app-tcpproxy/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
