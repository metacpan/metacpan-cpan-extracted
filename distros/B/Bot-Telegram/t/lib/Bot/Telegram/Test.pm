package Bot::Telegram::Test;

use Mojo::Base -strict;
use Mojo::IOLoop;

use Test::MockObject;
use Test::MockObject::Extends;

use Mojo::JSON qw/encode_json decode_json/;
use Mojo::UserAgent;
use Mojo::Transaction::HTTP;

use WWW::Telegram::BotAPI;

use base 'Exporter';
our @EXPORT = qw {
  timer
  update
  loop_for_a_second
  random_valid_polling_response
  json_response
  bot_api
};

my @UPDATES = qw/message edited_message edited_channel_post callback_query/;

sub timer(&$) { Mojo::IOLoop -> timer(pop, pop) } ## no critic

sub loop_for_a_second {
  timer { Mojo::IOLoop -> stop } 1;
  Mojo::IOLoop -> start;
}

sub update {
  my ($type, $id) = @_;

  return {
    $type => {
      foo => 'bar',
      baz => 'qux',
    },

    update_id => $id,
  };
}

sub json_response(;$) { ## no critic
  Mojo::Message::Response
    -> new
    -> body(encode_json shift);
}

sub random_valid_polling_response {
  my $updates_count = shift // 3;

  json_response {
    ok => \1,
    result => [map { update $UPDATES[rand scalar @UPDATES], $_ } 1 .. $updates_count]
  }
}

# Error handling in synchronous mode
# mostly copypasted from WWW::Telegram::BotAPI sources
sub _handle_error_sync {
  my $tx = shift;
  my $response = $tx -> res -> json;

  unless (!$tx->error && $response && $response->{ok}) {
    $response ||= {};
    my $error = $response->{description} || WWW::Telegram::BotAPI::_mojo_error_to_string($tx);
    # Print either the error returned by the API or the HTTP status line.
    Carp::confess
      "ERROR: ", ($response->{error_code} ? "code " . $response->{error_code} . ": " : ""),
      $error || "something went wrong!";
  }

  $response
}

sub bot_api {
  # Request hook
  my $hook;
  $hook = pop if ref $_[$#_] eq 'CODE';

  my @responses = @_;

  my $api = Test::MockObject::Extends -> new(
    WWW::Telegram::BotAPI -> new(token => 'foobaz', async => 1)
  );

  $api -> mock(
    api_request => sub {
      my ($self, $method, $postdata, $cb) = @_;

      my $res = shift @responses;

      # No payload (e.g. deleteWebhook)
      if (ref $postdata eq 'CODE') {
        $cb = $postdata;
        $postdata = undef;
      }

      return 'responses pool depleted' unless $res;

      $hook -> ($method, $postdata)
        if ref $hook eq 'CODE';

      my $tx = Mojo::Transaction::HTTP -> new;
      $tx -> res($res);

      $tx -> res($res);

      return $self -> {async}
        ? timer { return $cb -> ($self -> {agent}, $tx) if ref $cb eq 'CODE' } 0.1
        : _handle_error_sync $tx;
    }
  );

  return $api;
}

1

__END__

=encoding utf8

=head1 DESCRIPTION

General-purpose testing functions

=head1 FUNCTIONS

=head2 timer

  timer { say 'Tick' } 1;

Registers a timer for the Mojo::IOLoop global singleton. Takes a coderef to execute and a delay (in seconds) before execution.

=head2 loop_for_a_second

  loop_for_a_second;

Run Mojo::IOLoop just for one second, then shut it back down.

=head2 json_response

  my $res = json_response { ok => \1, message => 'dummy' };
  say ref $res; # Mojo::Message::Response
  say $res -> json -> {message}; # dummy

Returns a new C<Mojo::Message::Response> instance. Takes an array/hash-ref (actually, any json-encodable data),
 converts it into json and assigns it to the C<body> property of the return value.

=head2 bot_api

Simulates L<WWW::Telegram::BotAPI> behavior. 
Calling the C<api_request> method of the returned value
 will supply your callback with C<Mojo::UserAgent> and C<Mojo::Transaction::HTTP> instances;
 the latter will hold whatever you passed to the constructor in its C<res> property.

  my $fake_res = json_response { ok => \1, url => 'https://foo.bar/webhook' };
  my $fake_api = bot_api $fake_res;

  $fake_api -> setWebhook({...}, sub {
    my ($ua, $tx) = @_;

    say $tx -> res -> json -> {url}; # says: https://foo.bar/webhook
  });

It is possible to pass multiple fake responses, in which case a new response will be shift()ed
 from the responses array every time for subsequent requests to the fake api.

Once the fake responses pool is depleted, no more timers will be scheduled when you call C<api_request>.

  my $fake_api = bot_api $res1, $res2;

  $fake_api -> api_request('doStuff', {...}, sub ($ua, $tx) {
    is_deeply $tx -> res, $res1; # okay
  });

  $fake_api -> api_request('doMoreStuff', {...}, sub ($ua, $tx) {
    is_deeply $tx -> res, $res2; # okay
  });

  $fake_api -> api_request('doMoreStuff', {...}, sub ($ua, $tx) {
    # this callback is never executed
  });

Note that subsequent C<api_request> calls will no longer return a valid C<Mojo::IOLoop> job identifier.
Instead, the C<'responses pool depleted'> terminator string is returned.
Note that any long polling related tests will die horribly at that point!

It is also possible to hook into C<api_request> and inspect the request data before it is "sent"
- just append a callback to the arguments list:

  my $fake_api = bot_api @fake_responses, sub {
    my ($api_method, $postdata) = @_;
  };

B<NOTE>: LWP mode is not implemented.

=head2 update

  my $fake_msg = update 'message',        1; # Now got a message with update_id == 1
  my $fake_cbq = update 'callback_query', 2; # Callback query,        update_id == 2

Generate an update object of the given type with the given ID.

Note that this is not a valid Telegram update object - it only includes the minimal subset of fields required for our testing.
