package AnyEvent::Net::MPD;

use strict;
use warnings;

our $VERSION = '0.001';

use Moo;
use MooX::HandlesVia;
extends 'AnyEvent::Emitter';

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

use Types::Standard qw(
  InstanceOf Int ArrayRef HashRef Str Maybe Bool CodeRef
);

use Log::Any;
my $log = Log::Any->get_logger( category => __PACKAGE__ );

has version => (
  is => 'ro',
  isa => Str,
  lazy => 1,
  init_arg => undef,
);

has auto_connect => (
  is => 'ro',
  isa => Bool,
  default => 0,
);

has state => (
  is => 'rw',
  isa => Str,
  init_arg => undef,
  default => 'created',
  trigger => sub {
    $_[0]->emit( state => $_[0]->{state} );
  },
);

has read_queue => (
  is => 'ro',
  isa => ArrayRef [CodeRef],
  lazy => 1,
  init_arg => undef,
  default => sub { [] },
  handles_via => 'Array',
  handles => {
    push_read    => 'push',
    pop_read     => 'pop',
    shift_read   => 'shift',
    unshift_read => 'unshift',
  },
);

has password => (
  is => 'ro',
  isa => Maybe[Str],
  lazy => 1,
);

has port => (
  is => 'ro',
  isa => Int,
  lazy => 1,
  default => sub { $ENV{MPD_PORT} // 6600 },
);

has host => (
  is => 'ro',
  isa => Str,
  lazy => 1,
  default => sub { $ENV{MPD_HOST} // 'localhost' },
);

has _uri => (
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  default => sub {
    my $self = shift;
      ( $self->password ? $self->password . '@' : q{} )
    . $self->host
    . ( $self->port     ? ':' . $self->port     : q{} )
  },
);

has [qw( handle socket )] => ( is => 'rw', init_arg => undef, );

{
  my @buffer;
  sub _parse_block {
    my $self = shift;
    return sub {
      my ($handle, $line) = @_;

      if ($line =~ /\w/) {
        $log->tracef('< %s', $line);
        if ($line =~ /^OK/) {
          if ($line =~ /OK MPD (.*)/) {
            $log->trace('Connection established');
            $self->{version} = $1;

            $self->send( password => $self->password )
              if $self->password and $self->state ne 'ready';

            $self->state( 'ready' );
          }
          else {
            $self->shift_read->( \@buffer );
            @buffer = ();
          }
        }
        elsif ($line =~ /^ACK/) {
          return $self->emit(error => $line );
          @buffer = ();
        }
        else {
          push @buffer, $line;
        }
      }

      $handle->push_read( line => $self->_parse_block );
    };
  }
}

# Set up response parsers for each command
my $parsers = { none => sub { @_ } };
{
  my $item = sub {
    return { map {
      my ($key, $value) = split /: /, $_, 2;
      $key => $value;
    } @{$_[0]} };
  };

  my $flat_list = sub { [ map { (split /: /, $_, 2)[1] } @{$_[0]} ] };

  my $base_list = sub {
    my @main_keys = @{shift()};
    my @list_keys = @{shift()};
    my @lines     = @{shift()};

    my @return;
    my $item = {};

    foreach my $line (@lines) {
      my ($key, $value) = split /: /, $line, 2;

      if ( grep { /$key/ } @main_keys ) {
        push @return, $item if defined $item->{$key};
        $item = { $key => $value };
      }
      elsif ( grep { /$key/ } @list_keys ) {
        unless (defined $item->{$key}) {
          $item->{$key} = []
        }
        push @{$item->{$key}}, $value;
      }
      else {
        $item->{$key} = $value;
      }
    }
    push @return, $item if keys %{$item};

    return \@return;
  };

  my $grouped_list = sub {
    my @lines = @{shift()};

    # What we are grouping
    my ($main) = split /:\s+/, $lines[0], 2;

    # How we are grouping, from top to bottom
    my (@categories, %categories);
    foreach (@lines) {
      my ($key) = split /:\s+/, $_, 2;

      if ($key ne $main) {
        push @categories, $key unless defined $categories{$key};
        $categories{$key} = 1;
      }
    }

    my $return = {};
    my $item;
    foreach my $line (@lines) {
      my ($key, $value) = split /:\s+/, $line, 2;

      if (defined $item->{$key}) {
        # Find the appropriate list of items or create a new one
        # and populate it
        my $pointer = $return;
        foreach my $key (@categories) {
          my $val = $item->{$key} // q{};
          $pointer->{$key}{$val} = {} unless defined $pointer->{$key}{$val};
          $pointer = $pointer->{$key}{$val};
        }
        $pointer->{$main} = [] unless defined $pointer->{$main};
        my $list = $pointer->{$main};

        push @{$list}, delete $item->{$main};

        # Start a new item
        $item = { $key => $value };
        next;
      }

      $item->{$key} = $value;
    }
    return $return;
  };

  # Untested commands: what do they return?
  # consume
  # crossfade

  my $file_list = sub { $base_list->( [qw( directory file )], [], @_ ) };

  $parsers->{$_} = $flat_list foreach qw(
    commands notcommands channels tagtypes urlhandlers listplaylist
  );

  $parsers->{$_} = $item foreach qw(
    currentsong stats idle status addid update
    readcomments replay_gain_status rescan
  );

  $parsers->{$_} = $file_list foreach qw(
    find playlistinfo listallinfo search find playlistid playlistfind
    listfiles plchanges listplaylistinfo playlistsearch listfind
  );

  $parsers->{list} = $grouped_list;

  foreach (
      [ outputs        => [qw( outputid )],  [] ],
      [ plchangesposid => [qw( cpos )],      [] ],
      [ listplaylists  => [qw( playlist )],  [] ],
      [ listmounts     => [qw( mount )],     [] ],
      [ listneighbors  => [qw( neighbor )],  [] ],
      [ listall        => [qw( directory )], [qw( file )] ],
      [ readmessages   => [qw( channel )],   [qw( message )] ],
      [ lsinfo         => [qw( directory file playlist )], [] ],
      [ decoders       => [qw( plugin )], [qw( suffix mime_type )] ],
    ) {

    my ($cmd, $header, $list) = @{$_};
    $parsers->{$cmd} = sub { $base_list->( $header, $list, @_ ) };
  }

  $parsers->{playlist} = sub {
    my $lines = [ map { s/^\w*?://; $_ } @{shift()} ];
    $flat_list->( $lines, @_ )
  };

  $parsers->{count} = sub {
    my $lines = shift;
    my ($main) = split /:\s+/, $lines->[0], 2;
    $base_list->( [ $main ], [qw( )], $lines, @_ )
  };

  $parsers->{sticker} = sub {
    my $lines = shift;
    return {} unless scalar @{$lines};

    my $single = ($lines->[0] !~ /^file/);

    my $base = $base_list->( [qw( file )], [qw( sticker )], $lines, @_ );
    my $return = [ map {
      $_->{sticker} = { map { split(/=/, $_, 2) } @{$_->{sticker}} }; $_;
    } @{$base} ];

    return $single ? $return->[0] : $return;
  };
}

{
  my $cv;

  sub idle {
    my ($self, @subsystems) = @_;

    $cv = AnyEvent->condvar;

    my $idle;
    $idle = sub {
      my $o = shift->recv;
      $self->emit( $o->{changed} );
      $self->send( idle => @subsystems, $idle ) unless $cv->ready;
    };
    $self->send( idle => @subsystems, $idle );

    return $cv;
  }

  sub noidle {
    my ($self) = @_;
    $cv->send if $cv;
    $self->send( 'noidle' );
    return $self;
  }
}

sub send {
  my $self = shift;
  my $opt  = ( ref $_[0] eq 'HASH' ) ? shift : {};
  my $cb = pop if ref $_[-1] eq 'CODE';
  my (@commands) = @_;

  # Normalise input
  if (ref $commands[0] eq 'ARRAY') {
    @commands = map {
      ( ref $_ eq 'ARRAY' ) ? join( q{ }, @{$_} ) : $_;
    } @{$commands[0]};
  }
  else {
    @commands = join q{ }, @commands;
  }

  my $command = '';
  # Remove underscores from command names
  @commands = map {
    my $args;
    ($command, $args) = split /\s/, $_, 2;
    $command =~ s/_//g unless $command =~ /^replay_gain_/;
    $args //= q{};
    "$command $args";
  } @commands;

  # Create block if command list
  if (scalar @commands > 1) {
    unshift @commands, "command_list_begin";
    push    @commands, "command_list_end";
  }

  my $parser = $opt->{parser} // $command;
  $parser = $parsers->{$parser} // $parsers->{none}
    unless ref $parser eq 'CODE';

  my $cv = AnyEvent->condvar( $cb ? ( cb => $cb ) : () );

  $self->push_read( sub {
    my $response = shift;
    $cv->send( $parser->( $response ) );
  });

  $log->tracef( '> %s', $_ ) foreach @commands;
  $self->handle->push_write( join("\n", @commands) . "\n" );

  return $cv;
}

sub get { shift->send( @_ )->recv }

sub until {
  my ($self, $name, $check, $cb) = @_;

  weaken $self;
  my $wrapper;
  $wrapper = sub {
    if ($check->(@_)) {
      $self->unsubscribe($name => $wrapper);
      $cb->(@_);
    }
  };
  $self->on($name => $wrapper);

  return $wrapper;
}

sub BUILD {
  my ($self, $args) = @_;

  $self->socket( $self->_build_socket );

  $self->connect if $self->auto_connect;
}

sub _build_socket {
  my $self = shift;

  my $socket = tcp_connect $self->host, $self->port, sub {
    my ($fh) = @_
      or die "MPD connect failed: $!";

    $log->debugf('Connecting to %s:%s', $self->host, $self->port);
    $self->handle(
      AnyEvent::Handle->new(
        fh => $fh,
        on_error => sub {
          my ($hdl, $fatal, $msg) = @_;
          $self->emit( error => $msg );
          $hdl->destroy;
        },
      )
    );

    $self->handle->on_read(sub {
      $self->handle->push_read( line => $self->_parse_block )
    });

    $self->handle->on_error(sub {
      my ($h, $fatal, $message) = @_;
      $self->emit( error => $message // 'Error' );
      $self->handle(undef);
    });

    $self->handle->on_eof(sub {
      my ($h, $fatal, $message) = @_;
      $self->emit( eof => $message // 'EOF' );
      $self->handle(undef);
    });
  };

  return $socket;
}

sub connect {
  my ($self) = @_;

  return $self if $self->state eq 'ready';

  my $cv = AnyEvent->condvar;
  $self->until( state => sub { $_[1] eq 'ready' }, sub {
    $cv->send;
  });
  $cv->recv;

  return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

AnyEvent::Net::MPD - A non-blocking interface to MPD

=head1 SYNOPSIS

  use AnyEvent::Net::MPD;

  my $mpd = AnyEvent::Net::MPD->new( host => $ARGV[0] )->connect;

  my @subsystems = qw( player mixer database );

  # Register a listener
  foreach my $subsystem (@subsystems) {
    $mpd->on( $subsystem => sub {
      my ($self) = @_;
      print "$subsystem has changed\n";

      # Stop listening if mixer changes
      $mpd->noidle if $subsystem eq 'mixer';
    });
  }

  # Send a command
  my $stats = $mpd->send( 'stats' );

  # Or in blocking mode
  my $status = $mpd->send( 'status' )->recv;

  # Which is the same as
  $status = $mpd->get( 'status' );

  print "Server is ", $status->{state}, " state\n";
  print "Server has ", $stats->recv->{albums}, " albums in the database\n";

  # Put the client in looping idle mode
  my $idle = $mpd->idle( @subsystems );

  # Set the emitter in motion, until the next call to noidle
  $idle->recv;

=head1 DESCRIPTION

AnyEvent::Net::MPD provides a non-blocking interface to an MPD server.

=head1 ATTRIBUTES

=over 4

=item B<host>

The host to connect to. Defaults to B<localhost>.

=item B<port>

The port to connect to. Defaults to B<6600>.

=item B<password>

The password to use to connect to the server. Defaults to undefined, which
means to use no password.

=item B<auto_connect>

If set to true, the constructor will block until the connection to the MPD
server has been established. Defaults to false.

=back

=head1 METHODS

=over 4

=item B<connect>

If the client is not connected, wait until it is. Otherwise, do nothing.
Returns the client itself;

=item B<send> $cmd

=item B<send> $cmd => @args

=item B<send> [ $cmd1 $cmd2 $cmd3 ]

Send a command to the server in a non-blocking way. This command always returns
an L<AnyEvent> condvar.

If called with a single string, then that string will be sent as the command.

If called with a list, the list will be joined with spaces and sent as the
command.

If called with an array reference, then the value of each of item in that array
will be processed as above (with array references instead of plain lists). If
the referenced array contains more than one command, then these will be sent to
the server as a command list.

An optional subroutine reference passed as the last argument will be passed to
the condvar constructor, and fire when the condvar is ready (= when there is a
response from the server).

The response from the server will be parsed with a command-specific parser, to
provide some structure to the flat lists returned by MPD. If no parser is
found, or if the user specifically asks for no parser to be used (see below),
then the response will be an array reference with the raw lines from the server.

Finally, a hash reference with additional options can be passed as the I<first>
argument. Valid keys to use are:

=over 4

=item B<parser>

Specify the parser to use for the response. Parser labels are MPD commands. If
the requested parser is not found, the fallback C<none> will be used.

Alternatively, if the value itself is a code reference, then that will be
called with a reference to the raw list of lines as its only argument.

=back

For ease of use, underscores in the final command name will be removed before
sending to the server (unless the command name requires them).

=item B<get>

Send a command in a blocking way. Internally calls B<send> and immediately
waits for the response.

=item B<idle>

Put the client in idle loop. This sends the C<idle> command and registers an
internal listener that will put the client back in idle mode after each server
response.

If called with a list of subsystem names, then the client will only listen to
those subsystems. Otherwise, it will listen to all of them.

If you are using this module for an event-based application (see below), this
will configure the client to fire the events at the appropriate times.

Returns an L<AnyEvent> condvar. Blocking on this conditional variable will wait
until the next call to B<noidle> (see below).

=item B<noidle>

Cancel the client's idle mode. Sends an undefined value to the condvar created
by B<idle> and breaks the internal idle loop.

=back

=head1 EVENTS

After calling B<idle>, the client will be in idle mode, which means that any
changes to the specified subsystemswill trigger a signal. When the client
receives this signal, it will fire an event named as the subsystem that fired
it.

The event will be fired with the client as the first argument, and the response
from the server as the second argument. This can safely be ignored, since the
server response will normally just hold the name of the subsystem that changed,
which you already know.

Event descriptions

=over 4

=item B<database>

The song database has been changed after B<update>.

=item B<udpate>

A database update has started or finished. If the database was modified during
the update, the B<database> event is also emitted.

=item B<stored_playlist>

A stored playlist has been modified, renamed, created or deleted.

=item B<playlist>

The current playlist has been modified.

=item B<player>

The player has been started stopped or seeked.

=item B<mixer>

The volume has been changed.

=item B<output>

An audio output has been added, removed or modified (e.g. renamed, enabled or
disabled)

=item B<options>

Options like repeat, random, crossfade, replay gain.

=item B<partition>

A partition was added, removed or changed.

=item B<sticker>

The sticket database has been modified.

=item B<subscription>

A client has subscribed or unsubscribed from a channel.

=item B<message>

A message was received on a channel this client is subscribed to.

=back

=head1 SEE ALSO

=over 4

=item * L<Net::MPD>

A lightweight blocking MPD library. Has fewer dependencies than this one, but
it does not curently support command lists. I took the idea of allowing for
underscores in command names from this module.

=item * L<Audio::MPD>

The first MPD library on CPAN. This one also blocks and is based on L<Moose>.
However, it seems to be unmaintained at the moment.

=item * L<Dancer::Plugin::MPD>

A L<Dancer> plugin to connect to MPD. Haven't really tried it, since I
haven't used Dancer...

=item * L<POE::Component::Client::MPD>

A L<POE> component to connect to MPD. This uses Audio::MPD in the background.

=back

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
