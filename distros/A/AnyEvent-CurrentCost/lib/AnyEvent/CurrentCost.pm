use strict;
use warnings;
package AnyEvent::CurrentCost;
{
  $AnyEvent::CurrentCost::VERSION = '1.130190';
}

# ABSTRACT: AnyEvent module for reading from Current Cost energy meters


use constant DEBUG => $ENV{ANYEVENT_CURRENT_COST_DEBUG};
use base qw/Device::CurrentCost/;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::SerialPort;
use Carp qw/croak carp/;
use Sub::Name;


sub new {
  my ($pkg, %p) = @_;
  croak $pkg.q{->new: 'callback' parameter is required} unless ($p{callback});
  my $self = $pkg->SUPER::new(%p);
  $self;
}

sub DESTROY { shift->cleanup }


sub cleanup {
  my $self = shift;
  print STDERR "cleanup\n" if DEBUG;
  delete $self->{handle};
  close $self->filehandle if (defined $self->filehandle);
}

sub _error {
  my ($self, $fatal, $message) = @_;
  $self->cleanup($message);
  $self->{on_error}->($fatal, $message) if ($self->{on_error});
}


sub open {
  my $self = shift;
  my $fh = $self->filehandle;
  my $handle =
    $fh
      ? AnyEvent::Handle->new(fh => $fh)
        : AnyEvent::SerialPort->new(serial_port =>
                                    [ $self->device,
                                      [ baudrate => $self->baud ] ]);
  print STDERR ref $self, "->open: created ", $handle, "\n" if DEBUG;
  $self->{handle} = $handle;
  $handle->on_error(subname 'on_error' => sub {
                      my ($handle, $fatal, $msg) = @_;
                      print STDERR $handle.": error $msg\n" if DEBUG;
                      $handle->destroy;
                      $self->_error($fatal, 'Error: '.$msg);
                    });
  $handle->on_rtimeout(subname 'on_rtimeout' => sub {
                         my $rbuf = \$handle->{rbuf};
                         carp $handle, ": Discarding '", $$rbuf, "'\n";
                         $$rbuf = '';
                         $handle->rtimeout(undef);
                       });
  $handle->on_read(subname 'on_read_cb' => sub {
                     my ($hdl) = @_;
                     $hdl->push_read(ref $self => $self,
                                     subname 'push_read_cb' => sub {
                                       $self->{callback}->(@_);
                                       1;
                                     });
                   });
}

sub _time_now {
  AnyEvent->now;
}


sub anyevent_read_type {
  my ($handle, $cb, $self) = @_;
  subname 'anyevent_read_type_reader' => sub {
    my $rbuf = \$handle->{rbuf};
    while (1) { # read all message from the buffer
      print STDERR "Before: ", (unpack 'H*', $$rbuf||''), "\n" if DEBUG;
      my $res = $self->read_one($rbuf);
      return unless ($res);
      print STDERR "After: ", (unpack 'H*', $$rbuf), "\n" if DEBUG;
      $handle->rtimeout($self->{discard_timeout}) if ($$rbuf && length $$rbuf);
      $res = $cb->($res);
    }
  }
}

1;

__END__
=pod

=head1 NAME

AnyEvent::CurrentCost - AnyEvent module for reading from Current Cost energy meters

=head1 VERSION

version 1.130190

=head1 SYNOPSIS

  # Create simple Current Cost reader with logging callback
  AnyEvent::CurrentCost->new(callback => sub { print $_[0]->summary },
                             device => '/dev/ttyUSB0');

  # start event loop
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

AnyEvent module for reading from Current Cost energy meters.

B<IMPORTANT:> This is an early release and the API is still subject to
change.

=head1 METHODS

=head2 C<new(%params)>

Constructs a new C<AnyEvent::CurrentCost> object.  The supported
parameters are:

=over

=item device

The name of the device to connect to.  The value should be a tty device
name.  The default is C</dev/ttyUSB0>.

=item callback

The callback to execute when a message is received.

=item history_callback

A function, taking a sensor id, a time interval and a hash reference
of data as arguments, to be called every time a new complete set of
history data becomes available.  The data hash reference has keys of
the number of intervals ago and values of the reading at that time.

=back

=head2 C<cleanup()>

This method attempts to destroy any resources in the event of a
disconnection or fatal error.

=head2 C<open()>

This method opens the serial port and configures it.

=head2 C<anyevent_read_type()>

This method is used to register an L<AnyEvent::Handle> read type
method to read Current Cost messages.

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

