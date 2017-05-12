use strict;
use warnings;
package AnyEvent::W800;
$AnyEvent::W800::VERSION = '1.142240';
# ABSTRACT: Module to support W800 RF receiver


use 5.006;
use constant DEBUG => $ENV{ANYEVENT_W800_DEBUG};
use Carp qw/croak/;
use base qw/AnyEvent::RFXCOM::Base Device::W800/;
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
  my $weak_self = $self;
  weaken $weak_self;

  my $handle = $self->{handle};
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
  $handle->push_read(ref $self => $weak_self,
                     subname 'push_read_cb' => sub {
                       $weak_self->{callback}->(@_);
                       $weak_self->_write_now();
                       return;
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
      $res = $cb->($res) and return $res;
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::W800 - Module to support W800 RF receiver

=head1 VERSION

version 1.142240

=head1 SYNOPSIS

  # Create simple W800 message reader with logging callback
  AnyEvent::W800->new(callback => sub { print $_[0]->summary },
                      device => '/dev/ttyUSB0');

  # start event loop
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

AnyEvent module to decode messages from an W800 RF receiver from WGL &
Associates.

B<IMPORTANT:> This API is still subject to change.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new W800 RF receiver object.  The only
supported parameter is:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or a C<hostname:port> for TCP-based serial port redirection.

The default is C</dev/w800> in anticipation of a scenario where a udev
rule has been used to identify the USB tty device of the W800.

=back

=head2 C<cleanup()>

This method attempts to destroy any resources in the event of a
disconnection or fatal error.

=head2 C<anyevent_read_type()>

This method is used to register an L<AnyEvent::Handle> read type
method to read W800 messages.

=head1 SEE ALSO

L<Device::W800>

W800 website: http://www.wgldesigns.com/w800.html

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
