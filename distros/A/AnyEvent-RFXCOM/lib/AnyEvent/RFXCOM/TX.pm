use strict;
use warnings;
package AnyEvent::RFXCOM::TX;
$AnyEvent::RFXCOM::TX::VERSION = '1.142240';
# ABSTRACT: AnyEvent module for an RFXCOM transmitter


use 5.008;
use constant DEBUG => $ENV{ANYEVENT_RFXCOM_TX_DEBUG};
use base qw/AnyEvent::RFXCOM::Base Device::RFXCOM::TX/;
use AnyEvent;
use Carp qw/croak/;
use Sub::Name;
use Scalar::Util qw/weaken/;


sub _handle_setup {
  my $self = shift;
  my $handle = $self->{handle};
  my $weak_self = $self;
  weaken $weak_self;
  $handle->on_rtimeout(subname 'on_rtimeout_cb' => sub {
    my ($handle) = @_;
    print STDERR $handle.": no ack\n" if DEBUG;
    $handle->rtimeout(0);
    $weak_self->_init_mode();
  });
  $handle->on_drain(subname 'on_drain_cb' => sub {
    my ($handle) = @_;
    return unless (defined $handle);
    print STDERR $handle.": on drain\n" if DEBUG;
    $handle->rtimeout_reset();
    $handle->rtimeout($weak_self->{ack_timeout});
  });
  $handle->on_read(subname 'on_read_cb' => sub {
    my ($handle) = @_;
    $handle->rtimeout(0);
    my $rbuf = \$handle->{rbuf};
    my $data = $$rbuf;
    $$rbuf = '';
    $weak_self->{callback}->($data) if ($weak_self->{callback});
    print STDERR $handle.": read ", (unpack 'H*', $data), "\n" if DEBUG;
    my $wait_record = $weak_self->{_waiting};
    if ($wait_record) {
      my ($time, $rec) = @$wait_record;
      push @{$rec->{result}}, $data;
      my $cv = $rec->{cv};
      $cv->end if ($cv);
    }
    $weak_self->_write_now();
    return;
  });
  1;
}

sub transmit {
  my $self = shift;
  my $cv = AnyEvent->condvar;
  my $res = [];
  my $weak_cv = $cv;
  weaken $weak_cv;
  $cv->cb(subname 'transmit_cb' => sub { $weak_cv->send($res->[0]) });
  $self->SUPER::transmit(args => [ cv => $cv, result => $res ], @_);
  return $cv;
}

sub _open {
  my $self = shift;
  $self->SUPER::_open($self->_open_condvar);
  return 1;
}

sub _open_serial_port {
  my ($self, $cv) = @_;
  my $fh = $self->SUPER::_open_serial_port;
  $cv->send($fh);
  return $cv;
}

sub DESTROY {
  $_[0]->cleanup;
}


sub cleanup {
  my ($self, $error) = @_;
  $self->SUPER::cleanup(@_);
  undef $self->{discard_timer};
  undef $self->{dup_timer};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::RFXCOM::TX - AnyEvent module for an RFXCOM transmitter

=head1 VERSION

version 1.142240

=head1 SYNOPSIS

  # Create simple RFXCOM message reader with logging callback
  my $tx = AnyEvent::RFXCOM::TX->new(device => '/dev/ttyUSB0');

  # transmit an X10 RF message
  my $cv = $tx->transmit(type => 'x10', command => 'on', device => 'a1');

  # wait for acknowledgement from transmitter
  $cv->recv;

=head1 DESCRIPTION

AnyEvent module for handling communication with an RFXCOM transmitter.

=head1 METHODS

=head2 C<new(%params)>

Constructs a new C<AnyEvent::RFXCOM::TX> object.  The supported
parameters are:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or a C<hostname:port> for TCP-based RFXCOM transmitters.  The
default is C</dev/rfxcom-tx>.  See C<Device::RFXCOM::TX> for more
information.

=item receiver_connected

This parameter should be set to a true value if a receiver is connected
to the transmitter.

=item flamingo

This parameter should be set to a true value to enable the
transmission for "flamingo" RF messages.

=item harrison

This parameter should be set to a true value to enable the
transmission for "harrison" RF messages.

=item koko

This parameter should be set to a true value to enable the
transmission for "klik-on klik-off" RF messages.

=item x10

This parameter should be set to a false value to disable the
transmission for "x10" RF messages.  This protocol is enable
by default in keeping with the hardware default.

=back

There is no option to enable homeeasy messages because they use either
the klik-on klik-off protocol or homeeasy specific commands in order
to trigger them.

=head2 C<cleanup()>

This method attempts to destroy any resources in the event of a
disconnection or fatal error.  It is not yet implemented.

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

AnyEvent(3)

RFXCOM website: http://www.rfxcom.com/

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
