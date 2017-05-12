use strict;
use warnings;
package AnyEvent::RFXCOM::RX;
$AnyEvent::RFXCOM::RX::VERSION = '1.142240';
# ABSTRACT: AnyEvent module for an RFXCOM receiver


use 5.008;
use constant DEBUG => $ENV{ANYEVENT_RFXCOM_RX_DEBUG};
use base qw/AnyEvent::RFXCOM::Base Device::RFXCOM::RX/;
use AnyEvent;
use Carp qw/croak/;
use Sub::Name;
use Scalar::Util qw/weaken/;


sub new {
  my ($pkg, %p) = @_;
  croak $pkg.'->new: callback parameter is required' unless ($p{callback});
  my $self = $pkg->SUPER::new(%p);
  $self;
}

sub _handle_setup {
  my $self = shift;
  my $handle = $self->{handle};
  my $weak_self = $self;
  weaken $weak_self;
  $handle->on_rtimeout(subname 'on_rtimeout_cb' => sub {
    my ($handle) = @_;
    my $rbuf = \$handle->{rbuf};
    print STDERR $handle, ": discarding '",
      (unpack 'H*', $$rbuf), "'\n" if DEBUG;
    $$rbuf = '';
    $handle->rtimeout(0);
  });
  $handle->on_timeout(subname 'on_timeout_cb' => sub {
    my ($handle) = @_;
    print STDERR $handle.": Clearing duplicate cache\n" if DEBUG;
    $weak_self->{_cache} = {};
    $handle->timeout(0);
  });
  $handle->on_read(subname 'on_read_cb' => sub {
    my ($hdl) = @_;
    $hdl->push_read(ref $self => $self,
                    subname 'push_read_cb' => sub {
                      $weak_self->{callback}->(@_);
                      $weak_self->_write_now();
                      return 1;
                    });
  });
  1;
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


sub anyevent_read_type {
  my ($handle, $cb, $self) = @_;

  my $weak_self = $self;
  weaken $weak_self;

  subname 'anyevent_read_type_reader' => sub {
    my ($handle) = @_;
    my $rbuf = \$handle->{rbuf};
    $handle->rtimeout($weak_self->{discard_timeout});
    $handle->timeout($weak_self->{dup_timeout});
    while (1) { # read all message from the buffer
      print STDERR "Before: ", (unpack 'H*', $$rbuf||''), "\n" if DEBUG;
      my $res = $weak_self->read_one($rbuf);
      unless ($res) {
        if (defined $res) {
          print STDERR "Ignoring duplicate\n" if DEBUG;
          next;
        }
        return;
      }
      print STDERR "After: ", (unpack 'H*', $$rbuf), "\n" if DEBUG;
      $res = $cb->($res);
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::RFXCOM::RX - AnyEvent module for an RFXCOM receiver

=head1 VERSION

version 1.142240

=head1 SYNOPSIS

  # Create simple RFXCOM message reader with logging callback
  AnyEvent::RFXCOM::RX->new(callback => sub { print $_[0]->summary },
                            device => '/dev/ttyUSB0');

  # start event loop
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

AnyEvent module for handling communication with an RFXCOM receiver.

=head1 METHODS

=head2 C<new(%params)>

Constructs a new C<AnyEvent::RFXCOM::RX> object.  The supported
parameters are:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or a C<hostname:port> for TCP-based RFXCOM receivers.  The
default is C</dev/rfxcom-rx>.  See C<Device::RFXCOM::RX> for more
information.

=item callback

The callback to execute when a message is received.

=back

=head2 C<cleanup()>

This method attempts to destroy any resources in the event of a
disconnection or fatal error.

=head2 C<anyevent_read_type()>

This method is used to register an L<AnyEvent::Handle> read type
method to read RFXCOM messages.

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
