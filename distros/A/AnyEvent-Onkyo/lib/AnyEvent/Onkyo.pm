use strict;
use warnings;
package AnyEvent::Onkyo;
{
  $AnyEvent::Onkyo::VERSION = '1.130220';
}
use base 'Device::Onkyo';
use AnyEvent::Handle;
use AnyEvent::SerialPort;
use Carp qw/croak carp/;
use Sub::Name;
use Scalar::Util qw/weaken/;

use constant {
  DEBUG => $ENV{ANYEVENT_ONKYO_DEBUG},
};


# ABSTRACT: AnyEvent module for controlling Onkyo/Integra AV equipment


sub new {
  my ($pkg, %p) = @_;
  croak $pkg.'->new: callback parameter is required' unless ($p{callback});
  my $self = $pkg->SUPER::new(device => 'discover', %p);
  $self;
}


sub command {
  my $self = shift;
  my $cv = AnyEvent->condvar;
  my $weak_cv = $cv;
  weaken $weak_cv;
  $self->SUPER::command(@_, subname 'command_cb' => sub {
                          $weak_cv->send() if ($weak_cv);
                        });
  return $cv;
}

sub _open {
  my $self = shift;
  $self->SUPER::_open($self->_open_condvar);
  return 1;
}

sub _open_tcp_port {
  my ($self, $cv) = @_;
  my $dev = $self->{device};
  print STDERR "Opening $dev as tcp socket\n" if DEBUG;
  my ($host, $port) = split /:/, $dev, 2;
  $port = $self->{port} unless (defined $port);
  $self->{handle} =
    AnyEvent::Handle->new(connect => [$host, $port],
                          on_connect => subname('tcp_connect_cb' => sub {
                            my ($hdl, $h, $p) = @_;
                            warn ref $self, " connected to $h:$p\n" if DEBUG;
                            $cv->send();
                          }),
                          on_connect_error =>
                          subname('tcp_connect_error_cb' => sub {
                            my ($hdl, $msg) = @_;
                            my $err =
                              (ref $self).": Can't connect to $dev: $msg";
                            warn "Connect error: $err\n" if DEBUG;
                            $self->cleanup($err);
                            $cv->croak;
                          }));
  return $cv;
}

sub _open_serial_port {
  my ($self, $cv) = @_;
  $self->{handle} =
    AnyEvent::SerialPort->new(serial_port =>
                              [ $self->device,
                                [ baudrate => $self->baud ] ]);
  $cv->send();
  return $cv;
}

sub _handle_setup {
  my $self = shift;
  my $handle = $self->{handle};
  my $weak_self = $self;
  weaken $weak_self;

  $handle->on_error(subname('on_error' => sub {
                              my ($hdl, $fatal, $msg) = @_;
                              print STDERR $hdl.": error $msg\n" if DEBUG;
                              $hdl->destroy;
                              if ($fatal) {
                                $weak_self->cleanup($msg);
                              }
                            }));

  $handle->on_eof(subname('on_eof' => sub {
                            my ($hdl) = @_;
                            print STDERR $hdl.": eof\n" if DEBUG;
                            $weak_self->cleanup('connection closed');
                          }));

  $handle->on_read(subname 'on_read_cb' => sub {
    my ($hdl) = @_;
    $hdl->push_read(ref $self => $self,
                    subname 'push_read_cb' => sub {
                      $weak_self->{callback}->(@_);
                      $weak_self->_write_now();
                      return 1;
                    });
  });

  $self->{handle}->on_timeout($self->{on_timeout}) if ($self->{on_timeout});
  $self->{handle}->timeout($self->{timeout}) if ($self->{timeout});
  1;
}

sub DESTROY {
  $_[0]->cleanup;
}


sub cleanup {
  my ($self, $error) = @_;
  print STDERR $self."->cleanup\n" if DEBUG;
  $self->{handle}->destroy if ($self->{handle});
  delete $self->{handle};
}

sub _open_condvar {
  my $self = shift;
  print STDERR $self."->open_condvar\n" if DEBUG;
  my $cv = AnyEvent->condvar;
  my $weak_self = $self;
  weaken $weak_self;

  $cv->cb(subname 'open_cb' => sub {
            print STDERR "start cb ", $weak_self->{handle}, " @_\n" if DEBUG;
            $weak_self->_handle_setup();
            $weak_self->_write_now();
          });
  $weak_self->{_waiting} = ['fake for async open'];
  return $cv;
}

sub _real_write {
  my ($self, $str, $desc, $cb) = @_;
  print STDERR "Sending: ", $desc, "\n" if DEBUG;
  $self->{handle}->push_write($str);
}

sub _time_now {
  AnyEvent->now;
}


sub anyevent_read_type {
  my ($handle, $cb, $self) = @_;

  my $weak_self = $self;
  weaken $weak_self;

  subname 'anyevent_read_type_reader' => sub {
    my ($handle) = @_;
    my $rbuf = \$handle->{rbuf};
    while (1) { # read all message from the buffer
      print STDERR "Before: ", (unpack 'H*', $$rbuf||''), "\n" if DEBUG;
      my $res = $weak_self->read_one($rbuf);
      return unless ($res);
      print STDERR "After: ", (unpack 'H*', $$rbuf), "\n" if DEBUG;
      $res = $cb->($res);
    }
  }
}

1;

__END__
=pod

=head1 NAME

AnyEvent::Onkyo - AnyEvent module for controlling Onkyo/Integra AV equipment

=head1 VERSION

version 1.130220

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Onkyo;
  $| = 1;
  my $cv = AnyEvent->condvar;
  my $onkyo = AnyEvent::Onkyo->new(device => 'discover',
                                   callback => sub {
                                     my $cmd = shift;
                                     print "$cmd\n";
                                     unless ($cmd =~ /^NLS/) {
                                       $cv->send;
                                     }
                                   });
  $onkyo->command('volume up');
  $cv->recv;

=head1 DESCRIPTION

AnyEvent module for controlling Onkyo/Integra AV equipment.

B<IMPORTANT:> This is an early release and the API is still subject to
change. The serial port usage is entirely untested.

=head1 METHODS

=head2 C<new(%params)>

Constructs a new AnyEvent::Onkyo object.  The supported parameters are:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or C<hostname:port> for TCP.  It may also be the string
'discover' in which case automatic discovery will be attempted.  This
value defaults to 'discover'.  Note that discovery is currently blocking
and not recommended.

=item callback

The code reference to execute when a message is received from the
device.  The callback is called with the body of the message as a
string as the only argument.

=item type

Whether the protocol should be 'ISCP' or 'eISCP'.  The default is
'ISCP' if a tty device was given as the 'device' parameter or 'eISCP'
otherwise.

=item baud

The baud rate for the tty device.  The default is C<9600>.

=item port

The port for a TCP device.  The default is C<60128>.

=item broadcast_source_ip

The source IP address that the discovery process uses for its
broadcast.  The default, '0.0.0.0', should work in most cases but
multi-homed hosts might need to specify the correct local interface
address.

=item broadcast_dest_ip

The IP address that the discovery process uses for its broadcast.  The
default, '255.255.255.255', should work in most cases.

=back

=head2 C<command($command)>

This method takes a command and returns a callback to notify the caller
when it has been sent.

=head2 C<cleanup()>

This method attempts to destroy any resources in the event of a
disconnection or fatal error.

=head2 C<anyevent_read_type()>

This method is used to register an L<AnyEvent::Handle> read type
method to read Current Cost messages.

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

