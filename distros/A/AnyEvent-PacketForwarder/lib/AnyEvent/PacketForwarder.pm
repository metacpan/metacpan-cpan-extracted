package AnyEvent::PacketForwarder;

use strict;
use warnings;

our $VERSION = '0.01';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(packet_forwarder);

use AnyEvent;
use AnyEvent::PacketReader;
use Errno qw(EPIPE EMSGSIZE EINTR EAGAIN EWOULDBLOCK ENODATA);
use Carp;
our @CARP_NOT = qw(AnyEvent::PacketReader);

our $QUEUE_SIZE = 10;

sub packet_forwarder {
    my $cb = pop;
    my ($in, $out, $templ, $max_load_length, $queue_size) = @_;
    $queue_size ||= $QUEUE_SIZE;

    # data is:   0:reader, 1:out, 2:queue_size, 3:queue, 4:cb, 5:out_watcher
    my $data = [ undef   , $out , $queue_size , []     , $cb , undef         ];
    $data->[0] = packet_reader $in, $templ, $max_load_length, sub { _packet($_[0], $data) };

    my $obj = \$data;
    bless $obj;
}

sub _push {
    my $data = $_[1];
    # use Data::Dumper;
    # print STDERR Data::Dumper->Dump([\@_, $data], [qw(@_ $data)]);
    if (length $_[0]) {
        my $queue = $data->[3];
        push @$queue, $_[0];
        $data->[0]->pause if @$queue == $data->[2];
        $data->[5] ||= AE::io $data->[1], 1, sub { _write($data) };
    }
}

sub _packet {
    my $data = $_[1];
    if (defined $_[0]) {
        # use Data::Dumper;
        # print STDERR Data::Dumper->Dump([$data], [qw($data)]);
        $data->[4]->($_[0]);
        _push(@_);
        return;
    }
    $data->[4]->();
    _fatal_write($data, ENODATA) unless defined $data->[5];
    undef $data->[0];
}

sub _write {
    my $data = shift;
    my $queue = $data->[3];
    while (@$queue) {
        unless (length $queue->[0]) {
            $data->[0]->resume if @$queue == $data->[2];
            shift @$queue;
            next;
        }

        my $bytes = syswrite($data->[1], $queue->[0]);
        if ($bytes) {
            substr($queue->[0], 0, $bytes, '');
        }
        elsif (defined $bytes) {
            _fatal_write($data, EPIPE);
        }
        else {
            $! == $_ and return for (EINTR, EAGAIN, EWOULDBLOCK);
            _fatal_write($data);
        }
        return;
    }
    unless (defined $data->[0]) {
        return _fatal_write($data, ENODATA);
    }
    undef $data->[5];
}

sub _fatal_write {
    my $data = shift;
    local $! = shift if @_;
    $data->[4]->(undef, 1);
}

sub push {
    my $data = ${shift()};
    _push($_[0], $data);
}

1;
__END__


=head1 NAME

AnyEvent::PacketForwarder - Forward packets between two sockets

=head1 SYNOPSIS

  use AnyEvent::PacketForwarder;

  $watcher = packet_forwarder $in_fh, $out_fh, sub {
      if (defined $_[0]) {
          print("packet being forwarded:\n", hexdump($_[0]));
      }
      else {
         print("error from packet forwarder (fatal: $_[1]): $!");
      }
  }

=head1 DESCRIPTION

  *********************************************************
  *** This is a very early release, anything may change ***
  *********************************************************

This module allows to forwards packets from one socket (or pipe) to
another one. The packets can be modified on the fly.

Under the hood this package implements a writing queue and combines it
with a packet reader as provided by the module
L<AnyEvent::PacketReader>.

=head2 Export

The module exports the following subroutine:

=over 4

=item $w = packet_forwarder $in, $out, $templ, $max_pkt_len, $queue_size, $cb

This function reads packets from the $in socket (or pipe) and writes
them to the C<$out> socket (or pipe).

The callback C<$cb> is called every time a new packet is read with the
full packet contents as its first argument. The callback can modify
the packet in place jsut changing the value of (C<$_[0]>).

The C<$templ> argument defines the format of the packets (see
L<AnyEvent::PacketReader/Unpack templates>).

C<$max_pkt_len> is the maximum acceptable packet length.

C<$queue_size> is the maximum number of packets that can be queued for
writing. Once the queue becomes full, the forwarder object stops
reading new packets from C<$in> until some packet is written to
C<$out>.

The arguments C<$templ>, C<$max_pkt_len>, C<$queue_size> are optional
and can be omited.

When some error happens the callback C<$cb> is invoked with an
undefined first argument. The cause of the error can be then retrieved
from C<$!>. A true value is passed as the second argument when the
error is in the writing side.

The following code shows how to handle errors correctly:

  my $w;
  $w = packet_forwarder $in, $out,
           sub {
               if (defined $_[0]) {
                   print "packet received!\n";
                   ...
               }
               else {
                   shutdown($in, 0);
                   if ($_[1]) {
                       # write errors are fatal!
                       print "write failed: $!\n";
                       shutdown($out, 1);
                       undef $w; # let the forwarder go
                   }
                   else {
                       print "read failed: $!\n";
                   }
               }
           };

The module uses the following specific errors:

=over 4

=item ENODATA

Indicates that no more data is available from the read side because of
some error or because the remote side closed the socket and that the
write queue has been exhausted.

You may have seen a non fatal error telling you that there was some
problem (or EOF) from the read side before this one arrives.

=back

=back

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::Socket>, L<AnyEvent::PacketReader>.

The scripts contained on the C<examples> directory.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
