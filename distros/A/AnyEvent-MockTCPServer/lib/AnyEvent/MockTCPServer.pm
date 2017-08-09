use strict;
use warnings;
package AnyEvent::MockTCPServer;
$AnyEvent::MockTCPServer::VERSION = '1.172150';
# ABSTRACT: Mock TCP Server using AnyEvent


1;

use constant {
  DEBUG => $ENV{ANYEVENT_MOCK_TCP_SERVER_DEBUG}
};
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Test::More;
use Sub::Name;


sub new {
  my $pkg = shift;
  my $finished_cv = AnyEvent->condvar;
  my $self =
    {
     connections => [],
     listening => AnyEvent->condvar,
     finished_cv => $finished_cv,
     host => '127.0.0.1',
     port => 0,
     timeout => 2,
     on_timeout => subname('default_client_on_timeout_cb' =>
                           sub {
                             $finished_cv->end;
                             die "server timeout\n";
                           }),
     @_
    };
  bless $self, $pkg;

  foreach (@{$self->{connections}}) {
    $finished_cv->begin;
  }

  $self->{server} =
    tcp_server $self->{host}, $self->{port}, subname('accept_cb' =>
      sub {
        my ($fh) = @_;
        print STDERR "In server: $fh ", fileno($fh), "\n" if DEBUG;
        my $handle;
        $handle =
          AnyEvent::Handle->new(fh => $fh,
                                on_error => subname('client_on_error_cb_'.$fh =>
                                  sub {
                                    my ($hdl, $fatal, $msg) = @_;
                                    warn "error $msg\n";
                                    $self->{on_error}->(@_)
                                      if ($self->{on_error});
                                    $hdl->destroy;
                                  }),
                                timeout => $self->{timeout},
                                on_timeout => $self->{on_timeout},
                               );
      print STDERR "Connection handle: $handle\n" if DEBUG;
      $self->{handles}->{$handle} = $handle;
      my $con = $self->{connections};
      unless (@$con) {
        die "Server received unexpected connection\n";
      }
      my $actions = shift @$con;
      print STDERR "Actions: ", (scalar @$actions), "\n" if DEBUG;
      unless (@$con) {
        delete $self->{server};
      }
      $self->next_action($handle, $actions);
    }), subname('prepare_cb' => sub {
      my ($fh, $host, $port) = @_;
      die "tcp_server setup failed: $!\n" unless ($fh);
      $self->{listening}->send([$host, $port]);
      0;
    });
  return $self;
}

sub DESTROY {
  my $self = shift;
  delete $self->{listening};
  delete $self->{server};
  foreach (values %{$self->{handles}}) {
    next unless (defined $_);
    $_->destroy;
    delete $self->{handles}->{$_};
  }
}


sub listening {
  shift->{listening};
}


sub connect_address {
  @{shift->listening->recv};
}


sub connect_host {
  shift->listening->recv->[0];
}


sub connect_port {
  shift->listening->recv->[1];
}


sub connect_string {
  join ':', shift->connect_address
}


sub finished_cv {
  my $self = shift;
  $self->{finished_cv};
}


sub next_action {
  my ($self, $handle, $actions) = @_;
  print STDERR 'In handle connection ', scalar @$actions, "\n" if DEBUG;
  my $action = shift @$actions;
  unless (defined $action) {
    print STDERR "closing connection\n" if DEBUG;
    $handle->push_shutdown;
    delete $self->{handles}->{$handle};
    $self->{finished_cv}->end;
    return;
  }
  my $method = shift @$action;
  print STDERR "executing action: ", $method, "\n" if DEBUG;
  $self->$method($handle, $actions, @$action);
}


sub send {
  my ($self, $handle, $actions, $send, $desc) = @_;
  print STDERR 'Sending: ', $send, ' ', $desc, "\n" if DEBUG;
  print STDERR 'Sending ', length $send, " bytes\n" if DEBUG;
  $handle->push_write($send);
  $self->next_action($handle, $actions);
}


sub packsend {
  my ($self, $handle, $actions, $data, $desc) = @_;
  my $send = $data;
  $send =~ s/\s+//g;
  print STDERR 'Sending: ', $send, ' ', $desc, "\n" if DEBUG;
  $send = pack 'H*', $send;
  print STDERR 'Sending ', length $send, " bytes\n" if DEBUG;
  $handle->push_write($send);
  $self->next_action($handle, $actions);
}


sub recv {
  my ($self, $handle, $actions, $recv, $desc) = @_;
  print STDERR 'Waiting for ', $recv, ' ', $desc, "\n" if DEBUG;
  my $len = length $recv;
  print STDERR 'Waiting for ', $len, " bytes\n" if DEBUG;
  $handle->push_read(chunk => $len,
                     sub {
                       my ($hdl, $data) = @_;
                       print STDERR "In receive handler\n" if DEBUG;
                       is($data, $recv,
                          '... correct message received by server - '.$desc);
                       $self->next_action($hdl, $actions);
                       1;
                     });
}


sub recvline {
  my ($self, $handle, $actions, $recv, $desc) = @_;
  print STDERR 'Waiting for ', $recv, ' ', $desc, "\n" if DEBUG;
  print STDERR "Waiting for line\n" if DEBUG;
  $handle->push_read(line =>
                     sub {
                       my ($hdl, $data) = @_;
                       print STDERR "In receive handler\n" if DEBUG;
                       $recv = $recv->() if (ref $recv && ref $recv eq 'CODE');
                       if (ref $recv) {
                         like($data, $recv,
                            '... correct message received by server - '.$desc);
                       } else {
                         is($data, $recv,
                            '... correct message received by server - '.$desc);
                       }
                       $self->next_action($hdl, $actions);
                       1;
                     });
}


sub packrecv {
  my ($self, $handle, $actions, $data, $desc) = @_;
  my $recv = $data;
  $recv =~ s/\s+//g;
  my $expect = $recv;
  print STDERR 'Waiting for ', $recv, ' ', $desc, "\n" if DEBUG;
  my $len = .5*length $recv;
  print STDERR 'Waiting for ', $len, " bytes\n" if DEBUG;
  $handle->push_read(chunk => $len,
                     sub {
                       my ($hdl, $data) = @_;
                       print STDERR "In receive handler\n" if DEBUG;
                       my $got = uc unpack 'H*', $data;
                       is($got, $expect,
                          '... correct message received by server - '.$desc);
                       $self->next_action($hdl, $actions);
                       1;
                     });
}


sub sleep {
  my ($self, $handle, $actions, $interval, $desc) = @_;
  print STDERR 'Sleeping for ', $interval, ' ', $desc, "\n" if DEBUG;
  my $w;
  $w = AnyEvent->timer(after => $interval,
                       cb => sub {
                         $self->next_action($handle, $actions);
                         undef $w;
                       });
}


sub code {
  my ($self, $handle, $actions, $code, $desc) = @_;
  print STDERR 'Executing ', $code, ' for ', $desc, "\n" if DEBUG;
  $code->($self, $handle, $desc);
  $self->next_action($handle, $actions);
}

1;

__END__

=pod

=head1 NAME

AnyEvent::MockTCPServer - Mock TCP Server using AnyEvent

=head1 VERSION

version 1.172150

=head1 SYNOPSIS

  use AnyEvent::MockTCPServer qw/:all/;
  my $cv = AnyEvent->condvar;
  my $server =
    AnyEvent::MockTCPServer->new(connections =>
                                 [
                                  [ # first connection
                                   [ recv => 'HELLO', 'wait for "HELLO"' ],
                                   [ sleep => 0.1, 'wait 0.1s' ],
                                   [ code => sub { $cv->send('done') },
                                     'send "done" with condvar' ],
                                   [ send => 'BYE', 'send "BYE"' ],
                                   # ...
                                  ],
                                  [ # second connection
                                   # ...
                                  ]],
                                 # ...
                                );

=head1 DESCRIPTION

This module provides a TCP server with a set of defined behaviours for
use in testing of TCP clients.  It is intended to be use when testing
AnyEvent TCP client interfaces.

=head1 METHODS

=head2 C<new(%parameters)>

Constructs a new L<AnyEvent::MockTCPServer> object.  The parameter hash
can contain values for the following keys:

=over

=item C<connections>

A list reference containing elements for each expected connection.
Each element is another list reference contain action elements.  Each
action element is a list with an action method name and any arguments
to the action method.  By convention, the final argument to the action
method should be a description.  See the
L<action method|/ACTION METHODS> descriptions for the other arguments.

=item C<host>

The host IP that the server should listen on.  Default is the IPv4
loopback address, C<127.0.0.1>.

=item C<port>

The port that the server should listen on.  Default is to pick a
free port.

=item C<timeout>

The timeout for IO operations in seconds.  Default is 2 seconds.

=item C<on_timeout>

The callback to call when a timeout occurs.  Default is to die
with message C<"server timeout\n">.

=back

=head2 C<listening()>

Condvar that is notified when the mock server is ready.  The value
received is an array reference containing the address and port that
the server is listening on.

=head2 C<connect_address()>

An array reference containing the address and port that the server is
listening on.  This method blocks on the L</listening()> condvar until
the server is listening.

=head2 C<connect_host()>

The address that the server is listening on.  This method blocks on
the L</listening()> condvar until the server is listening.

=head2 C<connect_port()>

The port that the server is listening on.  This method blocks on
the L</listening()> condvar until the server is listening.

=head2 C<connect_string()>

A string containing the address and port that the server is listening
on separated by a colon, 'C<:>'.  This method blocks on the
L</listening()> condvar until the server is listening.

=head2 C<finished_cv()>

Condvar that is notified when the mock server has completed processing
of all the expected connections.

=head2 C<next_action($handle, $actions)>

Internal method called by the action methods when the server should
proceed with the next action.  Must be called by any action methods
written in subclasses of this class.

=head1 ACTION METHOD ARGUMENTS

These methods (and methods added by derived classes) can be used in
action lists passed via the constructor C<connections> parameter.  The
C<$handle> and C<$actions> arguments should be omitted from the action
lists as they are supplied by the framework.

=head1 ACTION METHODS

=head2 C<send($handle, $actions, $send, $desc)>

Sends the payload, C<$send>, to the client.

=head2 C<packsend($handle, $actions, $send, $desc)>

Sends the payload, C<$send>, to the client after removing whitespace
and packing it with 'H*'.  This method is equivalent to the
L</send($handle, $actions, $send, $desc)> method when passed the
packed string but debug messages contain the unpacked strings are
easier to read.

=head2 C<recv($handle, $actions, $expect, $desc)>

Waits for the data C<$expect> from the client.

=head2 C<recvline($handle, $actions, $expect, $desc)>

Waits for a line of data C<$expect> from the client.  See
L<AnyEvent::Handle> for the definition of 'line'.

=head2 C<packrecv($handle, $actions, $expect, $desc)>

Removes whitespace and packs the string C<$expect> with 'H*' and then
waits for the resulting data from the client.  This method is
equivalent to the L</recv($handle, $actions, $expect, $desc)> method
when passed the packed string but debug messages contain the unpacked
strings are easier to read.

=head2 C<sleep($handle, $actions, $interval, $desc)>

Causes the server to sleep for C<$interval> seconds.

=head2 C<code($handle, $actions, $code, $desc)>

Causes the server to execute the code reference with the client handle
as the first argument.

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2017 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
