use v5.14;
use AnyEvent::Discord::Payload;
use Test::More tests => 9;

my $example_gateway_dispatch = '{
  "op": 0,
  "d": {},
  "s": 42,
  "t": "GATEWAY_EVENT_NAME"
}';

my $payload = AnyEvent::Discord::Payload->from_json($example_gateway_dispatch);
ok( $payload, 'example_gateway_dispatch Coerced payload from raw json' );
is( $payload->op, 0, 'example_gateway_dispatch op = 0');
is( keys %{$payload->d}, 0, 'example_gateway_dispatch d = {}' );
is( $payload->t, 'GATEWAY_EVENT_NAME', 'example_gateway_dispatch t = GATEWAY_EVENT_NAME' );

my $example_identify = '{
  "op": 2,
  "d": {
    "token": "my_token",
    "intents": 513,
    "properties": {
      "$os": "linux",
      "$browser": "disco",
      "$device": "disco"
    },
    "compress": true,
    "large_threshold": 250,
    "guild_subscriptions": false,
    "shard": [0, 1],
    "presence": {
      "activities": [{
        "name": "Cards Against Humanity",
        "type": 0
      }],
      "status": "dnd",
      "since": 91879201,
      "afk": false
    },
    "intents": 7
  }
}';

$payload = AnyEvent::Discord::Payload->from_json($example_identify);
ok( $payload, 'example_identify Coerced payload from raw json' );
is( $payload->op, 2, 'example_identify op = 2');
is( keys %{$payload->d}, 8, 'example_identify d = { (8 keys) }' );
is( $payload->t,undef, 'example_identify t is missing' );

$payload = AnyEvent::Discord::Payload->from_hashref({
  op => 10,
  d => {
    made_up => 1
  }
});
my $json = $payload->as_json();
ok(
  (
    $json =~ /^\{.*\}$/
    and $json =~ /"op":10/
    and $json =~ /"d":\{"made_up":1\}/
  ),
  'made up payload to_json');

1;
