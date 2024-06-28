package Bot::Telegram;
# ABSTRACT: a micro^W nano framework for creating Telegram bots based on L<WWW::Telegram::BotAPI>
our $VERSION = '1.10'; # VERSION

use v5.16.3;

use Mojo::Base 'Mojo::EventEmitter';
use WWW::Telegram::BotAPI;
use Mojo::Promise;
use Mojo::Log;

use Mojo::JSON 'encode_json';
use Mojo::Transaction::HTTP;
use Mojo::Message::Response;

use Bot::Telegram::X::InvalidArgumentsError;
use Bot::Telegram::X::InvalidStateError;

use constant ERR_NODETAILS => 'no details available';

use constant DEFAULT_POLLING_TIMEOUT => 20;
use constant DEFAULT_POLLING_INTERVAL => 0.3;

use constant DEFAULT_POLLING_ERROR_CB => sub {
  my ($self, $tx, $type) = @_;

  my $message = sub {
    return $tx -> {error}{msg}
      unless $self -> is_async;

    for ($type) {
      /agent/ and return $tx -> error -> {message};
      /api/ and return ($tx -> res -> json // {}) -> {description};
    }
  } -> () || ERR_NODETAILS;

  $self -> log -> warn("Polling failed (error type: $type): $message");
};

use constant DEFAULT_CALLBACK_ERROR_CB => sub {
  my ($self, undef, $err) = @_;
  $self -> log -> warn("Update processing failed: $err");
};

has [qw/api current_update polling_config/];
has [qw/_polling
        _polling_timer
        _polling_interval
        _polling_request_id/
    ];

has callbacks => sub { {} };
has ioloop => sub { Mojo::IOLoop -> new };
has log => sub { Mojo::Log -> new -> level('info') };

sub new {
  my $self = shift -> SUPER::new(@_);

  $self -> on(polling_error  => DEFAULT_POLLING_ERROR_CB);
  $self -> on(callback_error => DEFAULT_CALLBACK_ERROR_CB);

  $self
}

################################################################################
# General
################################################################################

sub init_api {
  my ($self, %args) = @_;

  Bot::Telegram::X::InvalidArgumentsError
    -> throw('No token provided')
    unless exists $args{token};

  $args{async} //= 1;

  $self -> api(WWW::Telegram::BotAPI -> new(%args));

  return $self;
}

sub is_async {
  my $self = shift;

  Bot::Telegram::X::InvalidStateError
    -> throw('API is not initialized')
    unless $self -> api;

  $self -> api -> {async};
}

sub api_request { shift -> api -> api_request(@_) }
sub api_request_p {
  my ($self, @args) = @_;

  Mojo::Promise -> new(sub {
    my ($resolve, $reject) = @_;

    $self -> api -> api_request(@args, sub {
      my ($ua, $tx) = @_;
      my $response = $tx -> res -> json;

      ((!$tx -> error && ref $response && $$response{ok})
        ? $resolve
        : $reject) -> ($ua, $tx);
    })
  });
}

################################################################################
# Callbacks
################################################################################

sub set_callbacks {
  my ($self, %cbs) = @_;

  while ( my ($key, $val) = each %cbs) {
    $self -> callbacks -> {$key} = $val;
  }

  return $self;
}

sub remove_callbacks {
  my ($self, @events) = @_;

  foreach my $event (@events) {
    delete $self -> callbacks -> {$event};
  }

  return $self;
}

################################################################################
# Updates
################################################################################

sub shift_offset {
  my $self = shift;

  for (my $update = $self -> current_update) {
    $self -> polling_config -> {offset} = $$update{update_id} + 1
      if $$update{update_id} >= $self -> polling_config -> {offset};
  }

  $self
}

sub process_update {
  my ($self, $update) = @_;

  $self -> current_update($update);
  my $type = $self -> _get_update_type($update);

  eval {
    # If update type is recognized, call the appropriate callback
    if ($type) {
      $self -> callbacks
            -> {$type}
            -> ($self, $update);
    }

    # Otherwise report an unknown update
    else { $self -> emit(unknown_update => $update) }
  };

  # Report a callback error if we failed to handle the update
  $self -> emit(callback_error => $update, $@) if $@;

  return $self;
}

# Return the update type if we have a callback for it
# Or just return zero, if we don't
sub _get_update_type {
  my ($self, $update) = @_;

  exists $$update{$_}
    and return $_
    for keys %{ $self -> callbacks };

  return 0;
}

################################################################################
# Webhook
################################################################################

sub set_webhook {
  my ($self, $config, $cb) = @_;

  Bot::Telegram::X::InvalidStateError
    -> throw('Disable long polling first')
    if $self -> is_polling;

  Bot::Telegram::X::InvalidArgumentsError
    -> throw('No config provided')
    unless ref $config;

  $self -> api -> api_request(
    setWebhook => $config,
    ref $cb eq 'CODE' ? $cb : undef);

  return $self;
}

################################################################################
# Long polling
################################################################################

sub start_polling {
  my $self = shift;
  my $config = $self -> polling_config;
  if (ref $_[0] eq 'HASH') {
    $config = shift;
    $config -> {offset} //= 0; # make sure we won't get any uninitiailzed warnings in shift_offset
  }

  my (%opts) = @_;

  if ($opts{restart}) {
    $self -> stop_polling;
  } else {
    Bot::Telegram::X::InvalidStateError
      -> throw('Already running')
      if $self -> is_polling;
  }

  $self -> polling_config($config // { timeout => DEFAULT_POLLING_TIMEOUT, offset => 0 });

  $self -> _polling_interval($opts{interval} // DEFAULT_POLLING_INTERVAL);
  $self -> _polling(1);
  $self -> _poll;
}

sub stop_polling {
  my $self = shift;

  return $self unless $self -> is_polling;

  for (my $agent = $self -> api -> agent) {
    $self -> _polling(undef);

    # In synchronous mode, it's enough to simply clear state
    return $self -> _polling_interval(undef)
      unless $agent -> isa('Mojo::UserAgent')
      and $self -> is_async;

    # In asynchronous mode, we also need to cancel existing timers
    for (my $loop = Mojo::IOLoop -> singleton) {
      $loop -> remove($self -> _polling_request_id);
      $loop -> remove($self -> _polling_timer)
        if $self -> _polling_timer; # if another request is scheduled, cancel it
    }

    # Reset state
    $self -> _polling_request_id(undef)
          -> _polling_interval(undef)
          -> _polling_timer(undef);
  }

  $self
}

sub is_polling { !! shift -> _polling }

# In asynchronous mode: process getUpdates response or handle errors, if any
# In synchronous mode, WWW::Telegram::BotAPI::parse_error takes care of error handling for us.
sub _process_getUpdates_results {
  my $self = shift;
  my $async = $self -> is_async;
  my ($response, $error);

  $self -> log -> trace('processing getUpdates results');

  my $retry_after;

  if ($async) {
    my ($ua, $tx) = @_;
    $response = $tx -> res -> json // {};

    # Error
    if ($error = ($tx -> error or not $$response{ok})) {
      my $type = eval {
        return 'api' if $$response{error_code};
        return 'agent' if $tx -> error;
      } // 'unknown';

      $self -> emit(polling_error => $tx, $type);
    }
  } else {
    ($response, $error) = @_;
    # NOTE: $response and $error are mutually exclusive - only one is `defined` at a time

    if ($error) {
      $error = $self -> api -> parse_error;

      # no way to access the original $tx in synchronous mode
      # https://metacpan.org/dist/WWW-Telegram-BotAPI/source/lib/WWW/Telegram/BotAPI.pm#L228
      $self -> emit(polling_error => { error => $error }, $$error{type});
    }
  }

  # Handle rate limits
  if (exists $response -> {parameters}{retry_after}) {
    $retry_after = $response -> {parameters}{retry_after};
    $self -> log -> info("Rate limit exceeded, waiting ${retry_after}s before polling again");
  }

  # Process the updates we have retrieved (if any) and poll for more
  #  (unless someone or something has disabled the polling loop in the meantime)
  unless ($error) {
    for my $result ($$response{result}) {
      # last unless ref $result eq 'ARRAY'; # nothing to process

      $self -> process_update($_)
            -> shift_offset
        for @$result;
    }
  }

  return unless $self -> is_polling;
  $self -> log -> trace('still polling, scheduling another iteration...');

  if ($async) {
    my $tid = Mojo::IOLoop -> timer(
      $retry_after // $self -> _polling_interval,
      sub { $self -> tap(sub { $self -> log -> trace("it's polling time!") })
                  -> _poll });

    $self -> _polling_timer($tid);
  } else {
    my $d = $retry_after // $self -> _polling_interval;

    # Sleep
    $self -> ioloop -> timer($d, sub { $self -> ioloop -> stop });
    $self -> ioloop -> start;
    $self -> log -> trace("it's polling time!");

    $self -> _poll;
  }
}

sub _poll {
  my $self = shift;

  $self -> log -> trace('polling');

  if ($self -> is_async) {
    my $id = $self -> api -> api_request(
      getUpdates => $self -> polling_config,
      sub { $self -> _process_getUpdates_results(@_) }
    );

    # Assuming api_request always returns a valid ioloop connection ID when in asynchronous mode...
    $self -> _polling_request_id($id);
  } else {
    my $response = eval {
      $self -> api -> api_request(
        getUpdates => $self -> polling_config)
    };

    $self -> _process_getUpdates_results($response, $@);
  }
}

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Telegram - a micro^W nano framework for creating Telegram bots based on L<WWW::Telegram::BotAPI>

=head1 VERSION

version 1.10

=head1 SYNOPSIS

  #!/usr/bin/env perl

  use Mojo::Base -strict;
  use Bot::Telegram;

  my $bot = Bot::Telegram
    -> new
    -> init_api(token => YOUR_TOKEN_HERE);

  $bot -> set_callbacks(
    message => sub {
      my ($bot, $update) = @_;
      my $chat = $$update{message}{chat}{id};
      my $user = $$update{message}{from}{username};
      my $text = $$update{message}{text};

      say "> User $user says: $text";

      $bot -> api -> sendMessage(
        { chat_id => $chat, text => "Hello there, $user!" },
        sub {
          my ($ua, $tx) = @_;
          if ($tx -> res -> json -> {ok}) {
            say "> Greeted user $user";
          }
        }
      );
    },

    edited_message => sub { 
      my ($bot, $update) = @_;

      my $user = $$update{edited_message}{from}{username};
      say "> User $user just edited their message";
    },
  );

  # You might want to increase/disable inactivity timeouts for long polling
  $bot
    -> api
    -> agent
    -> inactivity_timeout(0);

  # Maybe remove some default subscribers...
  $bot -> unsubscribe('callback_error');

  # Or replace them with custom ones...
  $bot -> on(callback_error => sub {
    my $error = pop;
    $bot -> log -> fatal("update processing failed: $error");
    exit 255;
  });

  # Start long polling
  $bot -> start_polling;
  Mojo::IOLoop -> start;

=head1 DESCRIPTION

This package provides a tiny wrapper around L<WWW::Telegram::BotAPI> that takes care of the most annoying boilerplate,
especially for the long polling scenario.

Supports both synchronous and asynchronous modes of L<WWW::Telegram::BotAPI>.

Just like the aforementioned L<WWW::Telegram::BotAPI>, it doesn't rely too much on current state of the API
- only a few fields and assumptions are used for decision making
(namely, C<ok>, C<result>, C<description>, C<error_code> [presence], C<getUpdates> POST body format
and the assumption that C<getUpdates> response would be an array of update objects,
each consisting of two fields - C<update_id> and the other one, named after the update it represents and holding the actual update contents),
meaning we don't have to update the code every week just to keep it usable.

=head1 RATIONALE

L<WWW::Telegram::BotAPI> (which this module heavily depends on) is a low-level thing not responsible for
sorting updates by their types, setting up a long polling loop, etc,
and using it alone might not be sufficient for complex applications.
Even the simple L</"SYNOPSIS"> example will quickly become an if-for-eval mess, should we rewrite it in pure L<WWW::Telegram::BotAPI>,
and maintaining/extending such a codebase would be a disaster.

All other similar libraries available on CPAN are either outdated,
or incomplete, or... not very straightforward (imo),
so I made my own!

=head1 EVENTS

L<Bot::Telegram> inherits all events from L<Mojo::EventEmitter> and can emit the following new ones.

=head2 callback_error

  $bot -> on(callback_error => sub {
    my ($bot, $update, $error) = @_;
    warn "Update processing failed: $error";
  });

Emitted when a callback dies.

Default subscriber will log the error message using L</"log"> with the C<warn> log level:

  [1970-01-01 00:00:00.00000] [12345] [warn] Update processing failed: error details here

=head2 polling_error

  $bot -> on(polling_error => sub {
    my ($bot, $tx, $type) = @_;
  });

Emitted when a C<getUpdates> request fails inside the polling loop.

Keep in mind that the loop will keep working despite the error.
To stop it, you will have to call L</"stop_polling"> explicitly:

  $bot -> on(polling_error => sub { $bot -> stop_polling });

In synchronous mode, C<$tx> will be a plain hash ref.
The actual result of L<WWW::Telegram::BotAPI/"parse_error"> is available as the C<error> field of that hash.

  $bot -> on(polling_error => sub {
    my ($bot, $tx, $type) = @_;

    for ($type) {
      if (/api/) {
        my $error = ($tx -> res -> json // {}) -> {description};
      }

      elsif (/agent/) {
        if ($bot -> is_async) { # or `$tx -> isa('Mojo::Transaction::HTTP')`, if you prefer
          my $error = $tx -> error -> {message};
        } else {
          my $error = $tx -> {error}{msg};
        }
      }
    }
  });

In asynchronous mode, the logic responsible for making the "error type" decision is modelled after L<WWW::Telegram::BotAPI/"parse_error">,
meaning you will always receive same C<$type> values for same errors in both synchronous and asynchronous modes.

See L<WWW::Telegram::BotAPI/"parse_error"> for the list of error types and their meanings.

Default subscriber will log the error message using L</"log"> with the C<warn> log level:

  [1970-01-01 00:00:00.00000] [12345] [warn] Polling failed (error type: $type): error details here

=head2 unknown_update

  $bot -> on(unknown_update => sub {
    my ($bot, $update) = @_;
    say "> No callback defined for this kind of updates. Anyway, here's the update object:";

    require Data::Dump;
    Data::Dump::dd($update);
  });

Emitted when an update of an unregistered type is received.

The type is considered "unregistered" if there is no matching callback configured
 (i.e. C<$self -E<gt> callbacks -E<gt> {$update_type}> is not a coderef).

Exists mostly for debugging purposes.

There are no default subscribers to this event.

=head1 PROPERTIES

L<Bot::Telegram> inherits all properties from L<Mojo::EventEmitter> and implements the following new ones.

=head2 api

  my $api = $bot -> api;
  $bot -> api($api);

L<WWW::Telegram::BotAPI> instance used by the bot. Can be initialized via the L</"init_api"> method, or set directly.

=head2 callbacks

  my $callbacks = $bot -> callbacks;
  $bot -> callbacks($callbacks);

Hash reference containing callbacks for different update types.

While you can manipulate it directly, L</"set_callbacks"> and L</"remove_callbacks"> methods provide a more convinient interface.

=head2 current_update

  my $update = $bot -> current_update;
  say "User $$update{message}{from}{username} says: $$update{message}{text}";

Update that is currently being processed.

=head2 ioloop

  $loop = $bot -> ioloop;
  $bot -> ioloop($loop);

A L<Mojo::IOLoop> object used to delay execution in synchronous mode, defaults to a new L<Mojo::IOLoop> object.

=head2 log

  $log = $bot -> log;
  $bot -> log($log);

A L<Mojo::Log> instance used for logging, defaults to a new L<Mojo::Log> object with log level set to C<info>.

=head2 polling_config

  $bot -> polling_config($cfg);
  $cfg = $bot -> polling_config;

See C<$cfg> in L</"start_polling">.

=head1 METHODS

L<Bot::Telegram> inherits all methods from L<Mojo::EventEmitter> and implements the following new ones.

=head2 api_request

  $bot -> api_request('getMe');

Just a proxy function for the underlying L<WWW::Telegram::BotAPI/"api_request">.

The above statement is basically equivalent to:

  $bot -> api -> api_request('getMe');

except that it's shorter and adds another entry to your call stack.

=head2 api_request_p

  $p = $bot -> api_request_p('getMe');
  $p -> then(sub {
    my ($ua, $tx) = @_;
    say 1 if $res -> json -> {ok}; # always true
  }) -> catch(sub {
    my ($ua, $tx) = @_;

    if (my $err = $tx -> error) {
      die "$$err{code} response: $$err{message}"
        if $$err{code};

      die "Connection error: $$err{message}";
    } else {
      warn 'Action failed!';
      say {STDERR} $tx -> res -> json -> {description};
    }
  });

A promisified wrapper for the underlying L<WWW::Telegram::BotAPI/"api_request">.
The promise is rejected if there is an C<error> in C<$tx> or response is not C<ok>.
For both resolve and reject scenarios, the callback receives C<($ua, $tx)> from normal L<WWW::Telegram::BotAPI/"api_request">.

=head2 init_api

  $bot = $bot -> init_api(%args);

Automatically creates a L<WWW::Telegram::BotAPI> instance.

C<%args> will be proxied to L<WWW::Telegram::BotAPI/"new">.

For most use cases you only want to set C<$args{token}> to your bot's API token and leave everything else default.

B<NOTE:> the L<WWW::Telegram::BotAPI> instance created by L</"init_api"> defaults to the asynchronous mode.

=head3 Exceptions

=over 4

=item C<Bot::Telegram::X::InvalidArgumentsError>

No token provided

=back

=head2 is_async

  my $is_async = $bot -> is_async;

Returns true if the underlying L<WWW::Telegram::BotAPI> instance is in asynchronous mode.

=head3 Exceptions

=over 4

=item C<Bot::Telegram::X::InvalidStateError>

API is not initialized

=back

=head2 is_polling

  my $is_polling = $bot -> is_polling;

Returns true if the bot is currently in the long polling state.

=head2 process_update

  $bot = $bot -> process_update($update);

Process a single update and store it in L</"current_update">.

This function will not C<die> regardless of the operation success.
Instead, the L</"callback_error"> event is emitted if things go bad.

=head2 remove_callbacks

  $bot = $bot -> remove_callbacks(qw/message edited_message/);
  # From now on, bot considers 'message' and 'edited_message' unknown updates

Remove callbacks for given update types, if set.

=head2 set_callbacks

  $bot -> set_callbacks(
    message => sub {
      my ($bot, $update) = @_;
      handle_message $update;
    },

    edited_message => sub {
      my ($bot, $update) = @_;
      handle_edited_message $update;
    }
  );

Set callbacks to match specified update types.

=head2 set_webhook

  $bot = $bot -> set_webhook($config);
  $bot = $bot -> set_webhook($config, $cb);

Set a webhook. All arguments will be proxied to L<WWW::Telegram::BotAPI/"api_request">.

This function ensures that actual C<setWebhook> request will not be made as long as the polling loop is active:

  eval { $bot -> set_webhook($config) };

  if ($@ -> isa('Bot::Telegram::X::InvalidStateError')) {
    $bot -> stop_polling;
    $bot -> set_webhook($config);
  }

For deleting the webhook, just use plain API calls:

  $bot -> api_request(deleteWebhook => { drop_pending_updates => $bool }, sub { ... });

=head3 Exceptions

=over 4

=item C<Bot::Telegram::X::InvalidArgumentsError>

No config provided

=item C<Bot::Telegram::X::InvalidStateError>

Disable long polling first

=back

=head2 shift_offset

  $bot = $bot -> shift_offset;

Recalculate the current C<offset> for long polling.

Set it to the ID of L</"current_update"> plus one, if current update ID is greater than or equal to the current value.

This is done automatically inside the polling loop (L</"start_polling">),
but the method is made public, if you want to roll your own custom polling loop for some reason.

=head2 start_polling

  $bot = $bot -> start_polling;
  $bot = $bot -> start_polling($cfg);
  $bot = $bot -> start_polling(restart => 1, interval => 1);
  $bot = $bot -> start_polling($cfg, restart => 1, interval => 1);

Start long polling.

This method will block in synchronous mode.

Set L</"log"> level to C<trace> to see additional debugging information.

=head3 Arguments

=over 4

=item C<$cfg>

A hash ref containing L<getUpdates|https://core.telegram.org/bots/api#getupdates> options.
Note that the offset parameter is automatically incremented - whenever an update is processed (whether successfully or not),
the internally stored C<offset> value becomes update ID plus one,
IF update ID is greater than or equal to it.
The initial offset is zero by default.

The config is persistent between polling restarts and is available as L</"polling_config">.

  $bot -> start_polling($cfg);
  # ...
  $bot -> stop_polling;
  # ...
  $bot -> start_polling; # will reuse the previous config, offset preserved
  # ...
  say $bot -> polling_config eq $cfg; # 1

If none is provided and L</"polling_config"> is empty, a default config will be generated:

  { timeout => 20, offset => 0 }

=item restart

Set to true if the loop is already running, otherwise an exception will be thrown.

=item interval

Interval in seconds between polling requests.

Floating point values are accepted (timers are set using L<Mojo::IOLoop/"timer">).

Default value is 0.3 (300ms).

=back

=head3 Exceptions

=over 4

=item C<Bot::Telegram::X::InvalidStateError>

Already running

=back

=head2 stop_polling

  $bot = $bot -> stop_polling;

Stop long polling.

=head1 SEE ALSO

L<Bot::ChatBots::Telegram> - another library built on top of L<WWW::Telegram::BotAPI>

L<Telegram::Bot> - another, apparently incomplete, Telegram Bot API interface

L<Telegram::BotKit> - provides utilities for building reply keyboards and stuff, also uses L<WWW::Telegram::BotAPI>

L<WWW::Telegram::BotAPI> - lower level Telegram Bot API library used here

=head1 AUTHOR

Vasyan <somerandomtext111@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Vasyan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
