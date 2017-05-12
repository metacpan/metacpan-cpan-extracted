use strict;
use warnings;
package AnyEvent::OWNet;
$AnyEvent::OWNet::VERSION = '1.163170';
# ABSTRACT: Client for 1-wire File System server


use 5.008;
use constant DEBUG => $ENV{ANYEVENT_OWNET_DEBUG};
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Carp qw/croak/;
use Sub::Name;
use Try::Tiny;

use AnyEvent::OWNet::Constants;

use AnyEvent::OWNet::Response;


sub new {
  my ($pkg, %p) = @_;
  bless
    {
     connect_queue => [],
     host => '127.0.0.1',
     port => 4304,
     timeout => 5,
     %p,
    }, $pkg;
}

sub _msg {
  my ($self, $req) = @_;
  my $version = exists $req->{version} ? $req->{version} : 0;
  my $data = exists $req->{data} ? $req->{data} : '';
  my $payload = length $data;
  my $type =
    exists $req->{type} ? $req->{type} : OWNET_MSG_READ; # default to read
  my $sg = exists $req->{sg} ? $req->{sg} : OWNET_DEFAULT_FLAGS;
  my $size = exists $req->{size} ? $req->{size} : OWNET_DEFAULT_DATA_SIZE;
  my $offset = exists $req->{offset} ? $req->{offset} : 0;
  return pack 'N6a*', $version, $payload, $type, $sg, $size, $offset, $data;
}


sub read {
  my ($self, $path, $sub) = @_;
  $self->_run_cmd({ data => $path.chr(0), type => OWNET_MSG_READ }, $sub);
}


sub write {
  my ($self, $path, $value, $sub) = @_;
  $self->_run_cmd({ data => $path.chr(0).$value,
                   size => length $value,
                   type => OWNET_MSG_WRITE }, $sub);
}


sub dir {
  my ($self, $path, $sub) = @_;
  $self->_run_cmd({ data => $path."\0", type => OWNET_MSG_DIR, size => 0 },
                 $sub);
}


sub present {
  my ($self, $path, $sub) = @_;
  $self->_run_cmd({ data => $path."\0", type => OWNET_MSG_PRESENT }, $sub);
}


sub dirall {
  my ($self, $path, $sub) = @_;
  $self->_run_cmd({ data => $path."\0", type => OWNET_MSG_DIRALL }, $sub);
}


sub get {
  my ($self, $path, $sub) = @_;
  $self->_run_cmd({ data => $path."\0", type => OWNET_MSG_GET }, $sub);
}


sub dirallslash {
  my ($self, $path, $sub) = @_;
  $self->_run_cmd({ data => $path."\0", type => OWNET_MSG_DIRALLSLASH }, $sub);
}


sub getslash {
  my ($self, $path, $sub) = @_;
  $self->_run_cmd({ data => $path."\0", type => OWNET_MSG_GETSLASH }, $sub);
}

sub _run_cmd {
  my $self = shift;
  my $cmd  = shift;

  my ($cv, $cb);
  if (@_) {
    $cv = pop if UNIVERSAL::isa($_[-1], 'AnyEvent::CondVar');
    $cb = pop if ref $_[-1] eq 'CODE';
  }

  $cv ||= AnyEvent->condvar;

  print STDERR "using condvar $cv\n" if DEBUG;

  $cv->cb(subname 'command_cb' => sub {
            my $cv = shift;
            print STDERR "calling callback $cv\n" if DEBUG;
            try {
              my $res = $cv->recv;
              $cb->($res);
            } catch {
              ($self->{on_error} || sub { die "ARGH: @_\n"; })->($_);
            }
          }) if $cb;


  print STDERR 'Running command, ', $cmd->{type}, "\n" if DEBUG;
  if( $self->{handle} ){
    $self->_command_sub($cmd, $cv);
  } else {
    $self->connect($cmd, $cv );
  }

  return $cv;
}

sub DESTROY { }


sub all_cv {
  my $self = shift;
  $self->{all_cv} = shift if @_;
  unless ($self->{all_cv}) {
    $self->{all_cv} = AnyEvent->condvar;
    $self->{all_cv}->cb( sub { print STDERR "all_cv done\n" } ) if DEBUG;
  }
  $self->{all_cv};
}


sub cleanup {
  my $self = shift;
  print STDERR "cleanup\n" if DEBUG;
  $self->{all_cv}->croak(@_) if ($self->{all_cv});
  $self->{connect_cv}->croak( @_ ) if $self->{connect_cv};

  while (@{$self->{connect_queue}}) {
    my $queue = shift @{$self->{connect_queue}};
    my($cmd, $cv) = @$queue;
    $cv->croak(@_);
  }

  delete $self->{all_cv};
  delete $self->{connect_cv};
  delete $self->{sock};
  delete $self->{handle};
  $self->{on_error}->(@_) if $self->{on_error};
}


sub connect {
  my( $self, $cmd, $cv ) = @_;

  push @{$self->{connect_queue}}, [ $cmd, $cv ]
    if @_;

  # setup already ongoing
  return $self->{connect_cv}
    if $self->{connect_cv};

  # or start setup
  $self->{connect_cv} = AnyEvent->condvar;
  $self->{connect_cv}->cb( sub { print STDERR "connect_cv done\n" } ) if DEBUG;

  $self->{sock} = tcp_connect $self->{host}, $self->{port},
      subname 'tcp_connect_cb' => sub {

    my $fh = shift
      or do {
        my $err = "Can't connect owserver: $!";
        $self->cleanup($err);
        return
      };

    warn "Connected\n" if DEBUG;

    $self->{handle} = AnyEvent::Handle->new(
                            fh => $fh,
                            on_error => subname('on_error_cb' => sub {
                              print STDERR "handle error $_[2]\n" if DEBUG;
                              $_[0]->destroy;
                              if ($_[1]) {
                                $self->cleanup('Error: '.$_[2]);
                              }
                            }),
                            on_eof => subname('on_eof_cb' => sub {
                              print STDERR "handle eof\n" if DEBUG;
                              $_[0]->destroy;
                              $self->cleanup('Connection closed');
                            }),
                            on_timeout => subname('on_timeout_cb' => sub {
                              print STDERR "handle timeout\n" if DEBUG;
                              $_[0]->destroy;
                              $self->cleanup('Socket timeout');
                            })
                           );
    while (@{$self->{connect_queue}}) {
      my $queue = shift @{$self->{connect_queue}};
      $self->_command_sub(@$queue );
    }
    $self->{connect_cv}->send(1);
    delete $self->{connect_cv};
  };

  return $self->{connect_cv};
}


sub _command_sub {
  my( $self, $command, $cv ) = @_;

  $self->all_cv->begin;

  my $msg = $self->_msg($command);
  print STDERR "sending command ", $command->{type}, "\n" if DEBUG;
  warn 'Sending: ', (unpack 'H*', $msg), "\n" if DEBUG;

  $self->{handle}->push_write($msg);
  $self->{handle}->timeout($self->{timeout});

  $self->{handle}->push_read(ref $self, $command => subname 'push_read_cb' => sub {
                       my($handle, $res, $err) = @_;
                       $handle->timeout(0);
                       print STDERR "read finished $cv\n" if DEBUG;
                       print STDERR "read ",
                         ($cv->ready ? "ready" : "not ready"), "\n" if DEBUG;
                       $self->all_cv->end;
                       if ($err) {
                         print STDERR "returning error $err\n" if DEBUG;
                         return $cv->croak($res)
                       }
                       print STDERR "Sending $res\n" if DEBUG;
                       $cv->send($res);
                     });

  return $cv;
}


sub devices {
  my ($self, $cb, $offset, $cv) = @_;
  $offset ||= '/';
  $cv ||= AnyEvent->condvar;
  print STDERR "devices: $offset\n" if DEBUG;
  $cv->begin;
  $self->getslash($offset, subname 'devices_getslash_cb' => sub {
                    my $res = shift;
                    if ($res->is_success) {
                      foreach my $d ($res->data_list) {
                        if ($d =~ m!^.*/[0-9a-f]{2}\.[0-9a-f]{12}/$!i) {
                          $cb->($d, $cv);
                          $self->devices($cb, $d, $cv);
                        } elsif ($d =~ m!/(?:main|aux)/$!) {
                          $self->devices($cb, $d, $cv);
                        }
                      }
                    } # TOFIX: propagate error?
                    $cv->end;
                  });
  $cv;
}


sub device_files {
  my ($self, $cb, $files, $offset, $cv) = @_;
  $files = [$files] unless (ref $files);
  $cv = $self->devices(subname('device_files_devices_cb' => sub {
                 my $dev = shift;
                 foreach my $file (@$files) {
                   $cv->begin;
                   $self->get($dev.$file,
                              subname 'device_files_get_cb' => sub {
                                my $res = shift;
                                $cv->end;
                                my $value = $res->{data};
                                return unless (defined $value);
                                $cb->($dev, $file, 0+$value);
                              });
                 }
               }), $offset, $cv);
}


sub anyevent_read_type {
  my ($handle, $cb, $command) = @_;

  my $MAX_RETURN = 66000;
  my @data;
  subname 'anyevent_read_type_reader' => sub {
    my $rbuf = \$handle->{rbuf};

  REDO:
    return unless (defined $$rbuf);
    my $len;

    my %result;
    my $header;
    do {
      $len = length $$rbuf;
      print STDERR "read_type has $len bytes\n" if DEBUG;
      print STDERR "read_type has ", (unpack 'H*', $$rbuf), "\n" if DEBUG;
      return unless ($len >= 24);
      @result{qw/version payload ret sg size offset/} = unpack 'N6', $$rbuf;
      $header = substr $$rbuf, 0, 24, '';
      print STDERR "read_type header ", (unpack 'H*', $header), "\n" if DEBUG;
      if ($result{'ret'} > $MAX_RETURN) {
        $cb->($handle, AnyEvent::OWNet::Response->new(%result));
        return 1;
      }
    } while ($result{payload} > $MAX_RETURN);

    my $total_len = 24 + $result{payload};
    print STDERR "read_type have ", $len, " need ", $total_len, "\n" if DEBUG;
    unless ($len >= $total_len) {
      $$rbuf = $header.$$rbuf;
      return;
    }

    my $data = substr $$rbuf, 0, $result{payload}, '';
    if ($command->{type} == OWNET_MSG_DIR) {
      if ($data eq '') {
        $result{data} = \@data;
      } else {
        push @data, substr $data, 0, -1;
        goto REDO;
      }
    } else {
      $result{data} = $data;
    }
    print STDERR "read_type complete\n" if DEBUG;
    $cb->($handle, AnyEvent::OWNet::Response->new(%result));
    return 1;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::OWNet - Client for 1-wire File System server

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # IMPORTANT: the API is subject to change

  my $ow = AnyEvent::OWNet->new(host => '127.0.0.1',
                                on_error => sub { warn @_ });

  # Read temperature sensor
  $ow->read('/10.123456789012/temperature',
            sub {
              my ($res) = @_;
              # ...
            });

  # List all devices
  my $cv;
  $cv = $ow->devices(sub {
                       my $dev = shift;
                       print $dev, "\n";
                     });
  $cv->recv;

  # Read the temperatures of all devices that are found
  $cv = $ow->devices(sub {
                       my $dev = shift;
                       $cv->begin;
                       $ow->get($dev.'temperature',
                                sub {
                                  my $res = shift;
                                  $cv->end;
                                  my $value = $res->{data};
                                  return unless (defined $value);
                                  print $dev, ' = ', 0+$value, "\n";
                                });
                     });
  $cv->recv;

  # short version of the above
  $cv = $ow->device_files(sub {
                            my ($dev, $file, $value) = @_;
                            print $dev, ' = ', 0+$value, "\n";
                          }, 'temperature');
  $cv->recv;

  # read humidity as well
  $cv = $ow->device_files(sub {
                            my ($dev, $file, $value) = @_;
                            print $dev, $file, ' = ', 0+$value, "\n";
                          }, ['temperature', 'humidity']);
  $cv->recv;

=head1 DESCRIPTION

AnyEvent module for handling communication with an owfs 1-wire server
daemon.

=head1 METHODS

=head2 C<new( %parameter_hash )>

Constructs a new L<AnyEvent::OWNet> object.  The parameter hash can contain
values for the following keys:

=over

=item C<host>

The host IP of the running C<owserver> daemon.  Default is the IPv4
loopback address, C<127.0.0.1>.

=item C<port>

The TCP port of the running C<owserver> daemon.  Default is C<4304>.

=item C<timeout>

The timeout in seconds to wait for responses from the server.  Default
is 5 seconds.

=back

=head2 C<read($path, $sub)>

Perform an OWNet C<read> operation for the given path.

=head2 C<write($path, $value, $sub)>

Perform an OWNet C<write> operation of the given value to the given path.

=head2 C<dir($path, $sub)>

Perform an OWNet C<dir> operation for the given path.  The callback
will be called once with the list of directory entries in the data
field which isn't consistent with the (misguided?) low-latency intent
of this operation so using L<dirall()|/"dirall($path, $sub)"> probably
makes more sense provided the server supports it.

=head2 C<present($path, $sub)>

Perform an OWNet C<present> check on the given path.

=head2 C<dirall($path, $sub)>

Perform an OWNet C<dirall> operation on the given path.

=head2 C<get($path, $sub)>

Perform an OWNet C<get> operation on the given path.

=head2 C<dirallslash($path, $sub)>

Perform an OWNet C<dirall> operation on the given path.

=head2 C<getslash($path, $sub)>

Perform an OWNet C<get> operation on the given path.

=head2 C<all_cv( [ $condvar ] )>

This method returns the L<AnyEvent> condvar that is used to track all
outstanding operations.  It can also be used to set the initial value
but this is only sensible when no operations are currently outstanding
and is not normally necessary.

=head2 C<cleanup( @error )>

This method is called on error or when the closing the connection to
free up resources and notify any receivers of errors.

=head2 C<connect( [ $command, $callback|$condvar ] )>

This method connects to the C<owserver> daemon.  It is called automatically
when the first command is attempted.

=head2 C<devices( $callback, [ $path, [ $condvar ] ] )>

This method identifies all devices below the given path (or '/' if the
path is not given).  An C<AnyEvent> condvar may also be supplied that
will be used to track C<begin> and C<end> of all actions carried out
during the identification process.  If no condvar is provided then one
will be created.  The condvar used is returned by this method.

The supplied callback is called for each device with the path to each
device as the first argument and the condvar for the operation as the
second argument.  The intention of passing the callback the condvar
(that if not provided is created by the initial call) is to enable the
callbacks that need to make further asynchronous calls to use C<begin>
calls and C<end> calls (in the async callback) on the condvar so that
the complete operation may be tracked.  See the L</SYNOPSIS> for an
example.

This method currently assumes that the C<owserver> supports the C<getslash>
function and if this is not the case it will fail.

=head2 C<device_files( $callback, $file, [ $path, [ $condvar ] ] )>

Visit each device using
L<devices()|/"devices( $callback, [ $path, [ $condvar ] ] )"> and call
the callback with the result of successful L<get()|/"get($path, $sub)">
calls for C<$file> relative to each device found.  If C<$file> is an
array reference each array element is treated as a relative file.

=head2 C<anyevent_read_type()>

This method is used to register an L<AnyEvent::Handle> read type
to read C<OWNet> replies from an C<owserver> daemon.

=head1 TODO

The code assumes that the C<owserver> supports persistence and does
not check the response flags to recognize when it does not.

=head1 SEE ALSO

AnyEvent(3)

OWFS Website: http://owfs.org/

OWFS Protocol Document: http://owfs.org/index.php?page=owserver-protocol

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
