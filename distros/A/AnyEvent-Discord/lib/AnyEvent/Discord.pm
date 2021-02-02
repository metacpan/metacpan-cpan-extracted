package AnyEvent::Discord;
use v5.14;
use Moops;

class AnyEvent::Discord 0.6 {
  use Algorithm::Backoff::Exponential;
  use AnyEvent::Discord::Payload;
  use AnyEvent::WebSocket::Client;
  use Data::Dumper;
  use JSON qw(decode_json encode_json);
  use LWP::UserAgent;
  use HTTP::Request;
  use HTTP::Headers;

  our $VERSION = '0.6';
  has version => ( is => 'ro', isa => Str, default => $VERSION );

  has token => ( is => 'rw', isa => Str, required => 1 );
  has base_uri => ( is => 'rw', isa => Str, default => 'https://discordapp.com/api' );
  has socket_options => ( is => 'rw', isa => HashRef, default => sub { { max_payload_size => 1024 * 1024 } } );
  has verbose => ( is => 'rw', isa => Num, default => 0 );
  has user_agent => ( is => 'rw', isa => Str, default => sub { 'Perl-AnyEventDiscord/' . shift->VERSION } );

  has guilds => ( is => 'ro', isa => HashRef, default => sub { {} } );
  has channels => ( is => 'ro', isa => HashRef, default => sub { {} } );
  has users => ( is => 'ro', isa => HashRef, default => sub { {} } );

  # UserAgent
  has _ua => ( is => 'rw', default => sub { LWP::UserAgent->new() } );
  # Caller-defined event handlers
  has _events => ( is => 'ro', isa => HashRef, default => sub { {} } );
  # Internal-defined event handlers
  has _internal_events => ( is => 'ro', isa => HashRef, builder => '_build_internal_events' );
  # WebSocket
  has _socket => ( is => 'rw' );
  # Heartbeat timer
  has _heartbeat => ( is => 'rw' );
  # Last Sequence
  has _sequence => ( is => 'rw', isa => Num, default => 0 );
  # True if caller manually disconnected, to avoid reconnection
  has _force_disconnect => ( is => 'rw', isa => Bool, default => 0 );
  # Host the backoff algorithm for reconnection
  has _backoff => ( is => 'ro', default => sub { Algorithm::Backoff::Exponential->new( initial_delay => 4 ) } );

  method _build_internal_events() {
    return {
      'guild_create' => [sub { $self->_event_guild_create(@_); }],
      'guild_delete' => [sub { $self->_event_guild_delete(@_); }],
      'channel_create' => [sub { $self->_event_channel_create(@_); }],
      'channel_delete' => [sub { $self->_event_channel_delete(@_); }],
      'guild_member_create' => [sub { $self->_event_guild_member_create(@_); }],
      'guild_member_remove' => [sub { $self->_event_guild_member_remove(@_); }]
    };
  }

  method on(Str $event_type, CodeRef $handler) {
    $event_type = lc($event_type);
    $self->_debug('Requesting attach of handler ' . $handler . ' to event ' . $event_type);

    $self->_events->{$event_type} //= [];
    return if (scalar(grep { $_ eq $handler } @{$self->_events->{$event_type}}) > 0);

    $self->_debug('Attaching handler ' . $handler . ' to event ' . $event_type);
    push( @{$self->_events->{$event_type}}, $handler );
  }

  method off(Str $event_type, CodeRef $handler?) {
    $event_type = lc($event_type);
    $self->_debug('Requesting detach of handler ' . ($handler or 'n/a') . ' from event ' . $event_type);
    if ($self->_events->{$event_type}) {
      if ($handler) {
        my $index = 0;
        while ($index < scalar(@{$self->_events->{$event_type}})) {
          if ($self->_events->{$event_type}->[$index] eq $handler) {
            $self->_debug('Detaching handler ' . $handler . ' from event ' . $event_type);
            splice( @{$self->_events->{$event_type}}, $index, 1 );
          }
          $index++;
        }
      } else {
        $self->_debug('Detaching ' . scalar(@{$self->_events->{$event_type}}) . ' handler(s) from event ' . $event_type);
        delete($self->_events->{$event_type});
      }
    }
  }

  method connect() {
    my $gateway = $self->_lookup_gateway();

    $self->_debug('Connecting to ' . $gateway);

    my $ws = AnyEvent::WebSocket::Client->new($self->socket_options);
    $ws->connect($gateway)->cb(sub {
      my $socket = eval { shift->recv };
      if ($@) {
        $self->_debug('Received error connecting: ' . $@);
        $self->_handle_internal_event('error', $@);
        return;
      }
      $self->_debug('Connected to ' . $gateway);

      $self->_socket($socket);
  
      # If we send malformed content, bail out
      $socket->on('parse_error', sub {
        my ($c, $error) = @_;
        $self->_debug(Data::Dumper::Dumper($error));
        die $error;
      });

      # Handle reconnection
      $socket->on('finish', sub {
        my ($c) = @_;
        $self->_debug('Received disconnect');
        $self->_handle_internal_event('disconnected');
        unless ($self->_force_disconnect()) {
          my $seconds = $self->_backoff->failure();
          $self->_debug('Reconnecting in ' . $seconds);
          my $reconnect;
          $reconnect = AnyEvent->timer(
            after => $seconds,
            cb    => sub {
              $self->connect();
              $reconnect = undef;
            }
          );
        }
      });

      # Event handler
      $socket->on('each_message', sub {
        my ($c, $message) = @_;
        $self->_trace('ws in: ' . $message->{'body'});
        my $payload;
        try {
          $payload = AnyEvent::Discord::Payload->from_json($message->{'body'});
        } catch {
          $self->_debug($_);
          return;
        };
        unless ($payload and defined $payload->op) {
          $self->_debug('Invalid payload received from Discord: ' . $message->{'body'});
          return;
        }
        $self->_sequence(0 + $payload->s) if ($payload->s and $payload->s > 0);

        if ($payload->op == 10) {
          $self->_event_hello($payload);
        } elsif ($payload->d) {
          if ($payload->d->{'author'}) {
            my $user = $payload->d->{'author'};
            $self->users->{$user->{'id'}} = $user->{'username'};
          }
          $self->_handle_event($payload);
        }
      });

      $self->_discord_identify();
      $self->_debug('Completed connection sequence');
      $self->_backoff->success();
    });
  }

  method send($channel_id, $content) {
    $self->_discord_api('POST', 'channels/' . $channel_id . '/messages', encode_json({content => $content}));
  }

  method typing($channel_id) {
    return AnyEvent->timer(
      after    => 0,
      interval => 5,
      cb       => sub {
        $self->_discord_api('POST', 'channels/' . $channel_id . '/typing');
      },
    );
  }

  method close() {
    $self->_force_disconnect(1);
    $self->{'_heartbeat'} = undef;
    $self->{'_sequence'} = 0;
    $self->_socket->close();
  }

  # Make an HTTP request to the Discord API
  method _discord_api(Str $method, Str $path, $payload?) {
    my $headers = HTTP::Headers->new(
      Authorization => 'Bot ' . $self->token,
      User_Agent    => $self->user_agent,
      Content_Type  => 'application/json',
    );
    my $request = HTTP::Request->new(
      uc($method),
      join('/', $self->base_uri, $path),
      $headers,
      $payload,
    );
    $self->_trace('api req: ' . $request->as_string());
    my $res = $self->_ua->request($request);
    $self->_trace('api res: ' . $res->as_string());
    if ($res->is_success()) {
      if ($res->header('Content-Type') eq 'application/json') {
        return decode_json($res->decoded_content());
      } else {
        return $res->decoded_content();
      }
    }
    return;
  }

  # Send the 'identify' event to the Discord websocket
  method _discord_identify() {
    $self->_debug('Sending identify');
    $self->_ws_send_payload(AnyEvent::Discord::Payload->from_hashref({
      op => 2,
      d  => {
        token           => $self->token,
        compress        => JSON::false,
        large_threshold => 250,
        shard           => [0, 1],
        properties => {
          '$os'      => 'linux',
          '$browser' => $self->user_agent(),
          '$device'  => $self->user_agent(),
        }
      }
    }));
  }

  # Send a payload to the Discord websocket
  method _ws_send_payload(AnyEvent::Discord::Payload $payload) {
    unless ($self->_socket) {
      $self->_debug('Attempted to send payload to disconnected socket');
      return;
    }
    my $msg = $payload->as_json;
    $self->_trace('ws out: ' . $msg);
    $self->_socket->send($msg);
  }

  # Look up the gateway endpoint using the Discord API
  method _lookup_gateway() {
    my $payload = $self->_discord_api('GET', 'gateway');
    die 'Invalid gateway returned by API' unless ($payload and $payload->{url} and $payload->{url} =~ /^wss/);

    # Add the requested version and encoding to the provided URL
    my $gateway = $payload->{url};
    $gateway .= '/' unless ($gateway =~/\/$/);
    $gateway .= '?v=6&encoding=json';
    return $gateway;
  }

  # Dispatch an internal event type
  method _handle_internal_event(Str $type) {
    foreach my $event_source (qw(_internal_events _events)) {
      if ($self->{$event_source}->{$type}) {
        map {
          $self->_debug('Sending ' . ( $event_source =~ /internal/ ? 'internal' : 'caller' ) . ' event ' . $type);
          $_->($self);
        } @{ $self->{$event_source}->{$type} };
      }
    }
  }

  # Dispatch a Discord event type
  method _handle_event(AnyEvent::Discord::Payload $payload) {
    my $type = lc($payload->t);
    $self->_debug('Got event ' . $type);
    foreach my $event_source (qw(_internal_events _events)) {
      if ($self->{$event_source}->{$type}) {
        map {
          $self->_debug('Sending ' . ( $event_source =~ /internal/ ? 'internal' : 'caller' ) . ' event ' . $type);
          $_->($self, $payload->d, $payload->op);
        } @{ $self->{$event_source}->{$type} };
      }
    }
  }

  # Send debug messages to console if verbose is >=1
  method _debug(Str $message) {
    say $message if ($self->verbose);
  }

  # Send trace messages to console if verbose is 2
  method _trace(Str $message) {
    say $message if ($self->verbose == 2);
  }

  # Called when Discord provides the 'hello' event
  method _event_hello(AnyEvent::Discord::Payload $payload) {
    $self->_debug('Received hello event');
    my $interval = $payload->d->{'heartbeat_interval'}/1e3;
    $self->_heartbeat(
      AnyEvent->timer(
        after    => $interval,
        interval => $interval,
        cb       => sub {
          $self->_debug('Heartbeat');
          $self->_ws_send_payload(AnyEvent::Discord::Payload->from_hashref({
            op => 1,
            d  => $self->_sequence()
          }));
        }
      )
    );
  }

  # GUILD_CREATE event
  method _event_guild_create($client, HashRef $data, Num $opcode?) {
    $self->guilds->{$data->{'id'}} = $data->{'name'};

    # We get channel and user information along with the guild, populate those
    # at the same time
    foreach my $channel (@{$data->{'channels'}}) {
      if ($channel->{'type'} == 0) {
        $self->channels->{$channel->{'id'}} = $channel->{'name'};
      }
    }
    foreach my $user (@{$data->{'members'}}) {
      $self->users->{$user->{'user'}->{'id'}} = $user->{'user'}->{'username'};
    }
  }

  # GUILD_DELETE event
  method _event_guild_delete($client, HashRef $data, Num $opcode?) {
    delete($self->guilds->{$data->{'id'}});
  }

  # CHANNEL_CREATE event
  method _event_channel_create($client, HashRef $data, Num $opcode?) {
    $self->channels->{$data->{'id'}} = $data->{'name'};
  }

  # CHANNEL_DELETE event
  method _event_channel_delete($client, HashRef $data, Num $opcode?) {
    delete($self->channels->{$data->{'id'}});
  }

  # GUILD_MEMBER_CREATE event
  method _event_guild_member_create($client, HashRef $data, Num $opcode?) {
    $self->users->{$data->{'id'}} = $data->{'username'};
  }

  # GUILD_MEMBER_REMOVE event
  method _event_guild_member_remove($client, HashRef $data, Num $opcode?) {
    delete($self->users->{$data->{'id'}});
  }
}

1;

=pod

=head1 NAME

AnyEvent::Discord - Provides an AnyEvent interface to the Discord bot API

=head1 SYNOPSIS

 use AnyEvent::Discord;
 my $client = AnyEvent::Discord->new({ token => 'mydiscordbottoken' });
 $client->on('ready', sub { warn 'Connected'; });
 $client->on('message_create', sub {
   my ($client, $data) = @_;
   warn '[' . $client->channels->{$data->{channel_id}} . ']' .
        '(' . $data->{author}->{username} . ') - ' .
        $data->{content};
  });
  $client->connect();
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

This module provides an AnyEvent interface for the Discord API over the REST
and WebSocket APIs. It is designed to be somewhat similar to the SlackRTM and
XMPP modules, with a subset of their far more mature functionality.

To get started, one needs to create a new application in the Discord Developer
Portal (https://discord.com/developers). Once an application is created, a token
can be captured by navigating to the "Bot" tab on the left side and selecting
'Click to Reveal Token'. That generated token is the same token required by this
module.

=head1 CONFIGURATION ACCESSORS

=over 4

=item token (String) (required)

The token generated by the Discord Application portal, under Bot.

=item base_uri (String) (optional)

The base URI for communicating with the Discord API.

=item socket_options (HashRef) (optional)

Used to override options to sent to AnyEvent::WebSocket::Client, if needed.

=item verbose (Num) (defaults to 0)

Verbose output, writes internal debug information at 1, additionally writes
network conversation at 2.

=back

=head1 DATA ACCESSORS

=over 4

=item guilds

Available/created/seen guilds, as a hashmap of id => name

=item channels

Available/created/seen channels, as a hashmap of id => name

=item users

Available/created/seen users, as a hashmap of id => name

=back

=head1 PUBLIC METHODS

=over 4

=item new(\%arguments)

Instantiate the AnyEvent::Discord client. The hashref of arguments matches the
configuration accessors listed above. A common invocation looks like:

  my $client = AnyEvent::Discord->new({ token => 'ABCDEF' });

=item on($event_type, \&handler)

Attach an event handler to a defined event type. If an invalid event type is
specified, no error will occur -- this is mostly to be able to handle events
that are created after this module is published. This is an append method, so
calling on() for an event multiple times will call each callback assigned. If
the handler already exists for an event, no error will be returned, but the
handler will not be called twice.

Discord event types: https://discord.com/developers/docs/topics/gateway#list-of-intents

Opcodes: https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-opcodes

These events receive the parameters client, data object (d) and the opcode (op).

  sub event_responder {
    my ($client, $data, $opcode) = @_;
    return;
  }

Internal event types:

=over 4

=item disconnected

Receives no parameters, just notifies a disconnection will occur. It will
auto reconnect.

=item error

Receives an error message as a parameter, allows internal handling of errors
that are not a hard failure.

=back

=item off($event_type, \&handler?)

Detach an event handler from a defined event type. If the handler does not
exist for the event, no error will be returned. If no handler is provided, all
handlers for the event type will be removed.

=item connect()

Start connecting to the Discord API and return immediately. In a new AnyEvent
application, this would come before executing "AnyEvent->condvar->recv". This
method will retrieve the available gateway endpoint, create a connection,
identify itself, begin a heartbeat, and once complete, Discord will fire a
'ready' event to the handler.

=item send($channel_id, $content)

Send a message to the provided channel.

=item typing($channel_id)

Starts the "typing..." indicator in the provided channel. This method issues the
typing request, and starts a timer on the caller's behalf to keep the indicator
active. Returns an instance of that timer to allow the caller to undef it when
the typing indicator should be stopped.

  my $instance = $client->typing($channel);
  # ... perform some actions
  $instance = undef;
  # typing indicator disappears

=item close()

Close the connection to the server.

=back

=head1 CAVEATS

This is incredibly unfinished.

=head1 AUTHOR

Nick Melnick <nmelnick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, Nick Melnick.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
