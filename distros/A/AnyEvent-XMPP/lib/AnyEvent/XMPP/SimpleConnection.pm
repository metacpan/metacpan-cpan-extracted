package AnyEvent::XMPP::SimpleConnection;
use strict;
no warnings;

use AnyEvent;
use IO::Handle;
use Encode;
use AnyEvent::Socket;
use AnyEvent::Handle;

=head1 NAME

AnyEvent::XMPP::SimpleConnection - Low level TCP/TLS connection

=head1 SYNOPSIS

   package foo;
   use AnyEvent::XMPP::SimpleConnection;

   our @ISA = qw/AnyEvent::XMPP::SimpleConnection/;

=head1 DESCRIPTION

This module only implements the basic low level socket and SSL handling stuff.
It is used by L<AnyEvent::XMPP::Connection> and you shouldn't mess with it :-)

(NOTE: This is the part of AnyEvent::XMPP which I feel least confident about :-)

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = {
      disconnect_cb => sub {},
      @_
   };
   bless $self, $class;
   return $self;
}

sub connect {
   my ($self, $host, $service, $timeout) = @_;

   $self->{handle}
      and return 1;

   $self->{handle} = tcp_connect $host, $service, sub {
      my ($fh, $peerhost, $peerport) = @_;

      unless ($fh) {
         $self->disconnect ("Couldn't create socket to $host:$service: $!");
         return;
      }

      $self->{peer_host} = $peerhost;
      $self->{peer_port} = $peerport;

      binmode $fh, ":raw";

      $self->{handle} =
         AnyEvent::Handle->new (
            fh => $fh,
            on_eof => sub {
               $self->disconnect ("EOF on connection to $self->{peer_host}:$self->{peer_port}: $!");
            },
            autocork => 1,
            on_error => sub {
               $self->disconnect ("Error on connection to $self->{peer_host}:$self->{peer_port}: $!");
            },
            on_read => sub {
               my ($hdl) = @_;
               my $data   = $hdl->rbuf;
               $hdl->rbuf = '';
               $data      = decode_utf8 $data;
               $self->handle_data (\$data);
            },
         );
      
      $self->connected
      
   }, sub {
      $timeout
   };

   return 1;
}

sub connected {
   # subclass responsibility
}

sub send_buffer_empty {
   # subclass responsibility
}

sub block_until_send_buffer_empty {
   # subclass responsibility
}

sub debug_wrote_data {
   # subclass responsibility
}

sub end_sockets {
   my ($self) = @_;
   delete $self->{handle};
}

sub write_data {
   my ($self, $data) = @_;

   $self->{handle}->push_write (encode_utf8 ($data));
   $self->debug_wrote_data (encode_utf8 ($data));
   $self->{handle}->on_drain (sub {
      $self->send_buffer_empty;
   });
}

sub enable_ssl {
   my ($self) = @_;

   $self->{handle}->starttls ('connect');
   $self->{ssl_enabled} = 1;
}

sub disconnect {
   my ($self, $msg) = @_;
   $self->end_sockets;
   $self->{disconnect_cb}->($self->{peer_host}, $self->{peer_port}, $msg);
   $self->remove_all_callbacks;
}

1;
