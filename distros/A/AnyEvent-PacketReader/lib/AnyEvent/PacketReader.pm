package AnyEvent::PacketReader;

our $VERSION = '0.01';

use strict;
use warnings;
use 5.010;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(packet_reader);

use AnyEvent;
use Carp;
use Errno qw(EPIPE EBADMSG EMSGSIZE EINTR EAGAIN EWOULDBLOCK);

our $MAX_TOTAL_LENGTH = 1e6;

our $debug;

my %header_length = ( n => 2,
                      v => 2,
                      N => 4,
                      V => 4,
                      W => 1,
                      S => 2,
                      L => 4,
                      Q => 8 );

for my $dir (qw(> <)) {
    for my $t (qw(S L Q)) {
        $header_length{"$t$dir"} = $header_length{$t};
    }
}

my %short_templ = map { $_ => $_ } keys %header_length;
my %load_offset = %header_length;
my $good_packers = join '', keys %header_length;

use Data::Dumper;
$SIG{INT} = sub {
    print Data::Dumper->Dump([\%short_templ, \%header_length, \%load_offset], [qw(%short_templ %header_length %load_offset)]);
    exit 1;
};

sub packet_reader {
    my $cb = pop;
    my ($fh, $templ, $max_total_length) = @_;
    croak 'Usage: packet_reader($fh, [$templ, [$max_total_length,]] $callback)'
        unless defined $fh and defined $cb;

    $max_total_length ||= $MAX_TOTAL_LENGTH;
    my ($header_length, $load_offset, $short_templ);

    if (defined $templ) {
        unless (defined($short_templ = $short_templ{$templ})) {
            $debug and warn "PR: examining template '$templ'\n";
            my $load_offset;
            if ($templ =~ /^(x+)(\d*)/g) {
                $header_length = length($1) + (length $2 ? $2 - 1 : 0);
            }
            elsif ($templ =~ /^\@!(\d*)/g) {
                $header_length = (length $1 ? $1 : 1);
            }
            else {
                $header_length = 0;
            }

            $templ =~ /\G([$good_packers][<>]?)/go
                or croak "bad header template '$templ'";

            $header_length += ($header_length{$1} // die "Internal error: \$header_length{$1} is not defined");

            $short_templ = substr $templ, 0, pos($templ);


            if ($templ =~ /\G\@!(\d*)/g) {
                $load_offset =  (length $1 ? $1 : 1);
            }
            else {
                $load_offset = $header_length;
                if ($templ =~ /\G(x+)(\d*)/g) {
                    $load_offset += length $1 + (length $2 ? $2 - 1 : 0);
                }
            }

            $templ =~ /\G$/g or croak "bad header template '$templ'";

            $short_templ{$templ} = $short_templ;
            $header_length{$templ} = $header_length;
            $load_offset{$templ} = $load_offset;
            $debug and warn "PR: template '$templ' examined, header_length: $header_length, load_offset: $load_offset\n";
        }

        $header_length = $header_length{$templ};
        $load_offset = $load_offset{$templ};

    }
    else {
        $debug and warn "PR: defaulting to template 'N'\n";
        $templ = 'N';
        $header_length = 4;
        $load_offset = 4;
    }

    # data is:  0:buffer, 1:fh, 2:watcher, 3:header_length, 4:total_length, 5:short_templ, 6:max_total_length, 7:cb, 8:load_offset
    my $data = [''      , $fh , undef    , $header_length , undef         , $short_templ , $max_total_length , $cb , $load_offset  ];
    my $obj = \$data;
    bless $obj;
    $obj->resume;
    $obj;
}

sub pause {
    my $data = ${shift()};
    $data->[2] = undef;
}

sub resume {
    my $data = ${shift()};
    if (defined(my $fh = $data->[1])) {
        $data->[2] = AE::io $fh, 0, sub { _read($data) };
    }
}

sub DESTROY {
    my $obj = shift;
    $debug and warn "PR: watcher is gone, aborting read\n" if ${$obj}->[3];
    @{$$obj} = ();
}

sub _hexdump {
    local ($!, $@);
    no warnings qw(uninitialized);
    while ($_[0] =~ /(.{1,32})/smg) {
        my $line = $1;
        my @c= (( map { sprintf "%02x",$_ } unpack('C*', $line)),
                (("  ") x 32))[0..31];
        $line=~s/(.)/ my $c=$1; unpack("c",$c)>=32 ? $c : '.' /egms;
        print STDERR "$_[1] ", join(" ", @c, '|', $line), "\n";
    }
    print STDERR "\n";

}

sub _read {
    my $data = shift;
    my $length = $data->[4] || $data->[3];
    my $offset = length $data->[0];
    my $remaining = $length - $offset;
    my $bytes = sysread($data->[1], $data->[0], $remaining, $offset);
    if ($bytes) {
        $debug and warn "PR: $bytes bytes read\n";
        if (length $data->[0] == $length) {
            unless (defined $data->[4]) {
                my $load_length = unpack $data->[5], $data->[0];
                unless (defined $load_length) {
                    $debug and warn "PR: unable to extract size field from header\n";
                    return _fatal($data, EBADMSG);
                }
                my $total_length = $data->[8] + $load_length;
                $debug and warn "PR: reading full packet ".
                    "(load length: $load_length, total: $total_length, current: $length)\n";

                if ($total_length > $data->[6]) {
                    $debug and warn "PR: received packet is too long\n";
                    return _fatal($data, EMSGSIZE)
                }
                if ($length < $total_length) {
                    $data->[4] = $total_length;
                    return;
                }
                # else, the packet is done
                if ($length > $total_length) {
                    $debug and warn "PR: header length ($length) > total length ($total_length)\n";
                    return _fatal($data, EBADMSG);
                }
            }

            $debug and warn "PR: packet read, invoking callback\n";
            $data->[7]->($data->[0]);
            # somebody may have taken a reference to the buffer so we start clean:
            @$data = ('', @$data[1..3], undef, @$data[5..$#$data]);
            $debug and warn "PR: waiting for a new packet\n";
        }
    }
    elsif (defined $bytes) {
        $debug and warn "PR: EOF!\n";
        return _fatal($data, EPIPE);
    }
    else {
        $debug and warn "PR: sysread failed: $!\n";
        $! == $_ and return for (EINTR, EAGAIN, EWOULDBLOCK);
        return _fatal($data);
    }
}

sub _fatal {
    my $data = shift;
    local $! = shift if @_;
    if ($debug) {
        warn "PR: fatal error: $!\n";
        _hexdump($data->[0], 'pkt:');
    }
    $data->[7]->();
    @$data = (); # release watcher;
}

1;
__END__
=head1 NAME

AnyEvent::PacketReader - Read packets from a socket

=head1 SYNOPSIS

  use AnyEvent::PacketReader;
  my $watcher = packet_reader $fh, 'N', sub { warn "packet read: $_[0]\n" };


=head1 DESCRIPTION

  *********************************************************
  *** This is a very early release, anything may change ***
  *********************************************************

This module allows to read packets from a socket easily.

The kind of packets that can be read are those composed by a header
and a body whose size is determined by a field in the header plus some
optional offset adjustment.

A C<unpack> style template is used to define the packet header size,
how to parse the body size and the optional body offset.

=head2 Unpack templates

The templates used to determine the header size, size slot offset and
encoding and body offset are a subset of those accepted by C<pack>:

The basic templates are those composed just by one of the following
integer packers that define how to extract the value of the length
slot from the header:

    n v N V W S S< S> L L< L> Q Q< Q>

The "<" and ">" modifiers indicate the endianess of the type. Note
also that the C<Q> packer is only supported on perls built with 64bit
integer support.

In order to indicate an offset for the size slot, the packer can be
prefixed by a particle of the form C<x$offset> (C<xxx...> is also a
valid variation).

To indicate that more bytes follow in the header after the size slot,
a C<x$offset> particle can also be included after. Alternatively a
C<@!$offset> particle can be used to indicate an absolute offset for
the body.

For instance, the three equivalent templates below can be used to read
packets with a 24bytes header where the body length is at offset 4
encoded in 4 bytes as a 32bits integer in network order.

   x4Nx16
   xxxxNxxxxxxxxxxxxxxxx
   x4N@!24

Probably, the most common usage of the C<@!$offset> particle is to
indicate that the value from the length slot includes the header
length (C<@!0>).

Some samples for real protocols will hopefully make things easier to
understand:

=over 4

=item SFTP

SFTP protocol packets start by a 4byte length field
followed by the packet load.

   +=====================================+
   | SFTP packet                         |
   +=====================================+
   |   Length    | Type |  Data payload  |
   +-------------+------+----------------+
   | <-4 bytes-> | <----Length bytes---> |
   +-------------+-----------------------+

 The template to use in that case is C<N>.

(see also L<http://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol>)

=item SMPP

SMPP protocol packets start by a 4byte slot containing the total
length of the packet including the length slot itself.

   +=================================================+
   | SMPP packet                                     |
   +=================================================+
   |   Length    | Id | Status | Sequence | PDU Body |
   +-------------+----+--------+----------+----------+
   | <-4 bytes-> |                                   |
   |-------------+                                   |
   |  <-------------------Length bytes------------>  |
   +-------------------------------------------------+

The template in that case is C<N@!0>. The C<N> extracts a 32bit
integer in network order from the packet and the C<@!0> sets the body
offset at 0.

The following code will dump the SMPP packets arriving at the socket
C<$socket>:

  my $w = packet_reader $socket, 'N@!0',
              sub {
                  if (defined $_[0]) {
                      hexdump($_[0]);
                  }
                  else {
                      warn "some error happened: $!"
                  }
               };

(see also L<http://en.wikipedia.org/wiki/Short_Message_Peer-to-Peer>)

=item IPv4

On IPv4 packet, the length slot starts at offset 2 and is encoded as a
16bit integer in network order. In that case the length is inclusive
of the packet header.

   +=========================================================+
   | IPv4 packet                                             |
   +=========================================================+
   | Version | IHL | DSCP | ECN | Total length  | ... | Data |
   +---------+-----+------+-----+---------------+-----+------+
   | <---------2 bytes--------> | <--2 bytes--> |            |
   |----------------------------+---------------+            |
   |  <-----------------------Length bytes---------------->  |
   +---------------------------------------------------------+

The template for reading IPv4 packets is C<xxn@!0>.

(see also L<http://en.wikipedia.org/wiki/Ipv4>)

=back

=head2 Export

The module exports the following subroutine:

=over 4

=item $watcher = packet_reader $socket, $template, $max_packet_len, $cb

This subroutine creates a new packet reader object that will keep
calling the given callback C<$cb> every time a new packet arrives at
the socket/pipe until an error happens or the returned watcher goes
out of scope.

Both the C<$template> and C<$max_packet> arguments are optional and
can be omited. The default template is C<N> and the default maximum
packet size is 1_000_000.

The callback is called with the full packet as its first argument.

If some error happens while reading from the socket the callback is
called with and undef value. The cause of the problem can be obtained
from C<$!>.

Some specific errors generated by the module are as follows:

=over 4

=item EPIPE

The socket has been closed at the other side (actually, just the
reading direction, it may still be possible to write to the socket).

=back EMSGSIZE

The packet exceeds the maximum allowed packet size.

=back EBADMSG

Unable to extract the packet size from the header or the size
extracted is not consistent (i.e. the resulting total packet size is
smaller than the part of the header already read).

=back

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::Socket>, L<AnyEvent::PacketForwarder>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
