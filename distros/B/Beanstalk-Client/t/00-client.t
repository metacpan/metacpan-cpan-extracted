
use Test::More tests => 24;

use_ok('Beanstalk::Stats');
use_ok('Beanstalk::Job');
use_ok('Beanstalk::Client');

{ package NoConnect;
  @ISA = qw(Beanstalk::Client);
  sub connect { return; }
}

my $client = NoConnect->new;

ok($client,"Create client");

is_deeply(
  [$client->list_tubes_watched],
  [],
  "list_tubes_watched return empty list on error"
);

# Connect to server running on localhost
$client = Beanstalk::Client->new;

unless ($client->connect) {
SKIP: {
    skip("Need local beanstalkd server running", 19);
  }
  exit(0);
}

is(
  $client->list_tube_used,
  'default',
  "Using default tube"
);

is(
  $client->ignore('default'),
  undef,
  "Must watch a tube"
);

isa_ok(
  $client->stats_tube('default'),
  'Beanstalk::Stats',
  "Fetch tube stats"
);

my $yaml = <<YAML;
--- 1
--- 2
--- 
- 3
- 4
YAML

test_encoding($client, "YAML", $yaml, 1,2,[3,4]);
SKIP: {
  skip("Need JSON::XS", 4) unless eval { require JSON::XS };
  my $json_client = Beanstalk::Client->new(
    { encoder => sub { JSON::XS::encode_json(\@_) },
      decoder => sub { @{JSON::XS::decode_json(shift)} },
    }
  );
  test_encoding($json_client, "JSON", "[1,2,[3,4]]", 1,2,[3,4]);
}

# test priority override
$client->priority(9000);
my $job = $client->put({priority => 9001}, "foo");
$job = $job->peek;
is(9001, $job->priority, "got the expected priority");

$client->watch_only('foobar');
is_deeply( [$client->list_tubes_watched], ['foobar'], 'watch_only');
$client->watch_only('barfoo');
is_deeply( [$client->list_tubes_watched], ['barfoo'], 'watch_only');
is($client->use('foobar'), 'foobar', 'use');
is($client->list_tube_used, 'foobar', 'list_tube_used');
$client->disconnect;
is_deeply( [$client->list_tubes_watched], ['barfoo'], 'watch_only after disconnect');
is($client->list_tube_used, 'foobar', 'list_tube_used after disconnect');

$client = Beanstalk::Client->new;
is(
  $client->watch_only('foo'),
  1,
  "can call watch_only before connect"
);

sub test_encoding {
  my $client = shift;
  my $type = shift;
  my $data = shift;
  my @args = @_;

  $client->use("json_test");

  my $job = $client->put({},@args);
  is(
    $job->data,
    $data,
    "$type encoding"
  );
  is_deeply(
    [ $job->args ],
    \@args,
    "$type decoding"
  );
  $job = $job->peek;
  is(
    $job->data,
    $data,
    "$type encoding"
  );
  is_deeply(
    [ $job->args ],
    \@args,
    "$type decoding"
  );
}
