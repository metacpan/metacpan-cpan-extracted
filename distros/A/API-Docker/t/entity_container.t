#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use API::Docker::Role::Entity::Container;

# karr k79 step 6, for containers: the convenience methods live in
# API::Docker::Role::Entity::Container and are composed into the two generated
# classes the daemon answers container requests with. Nothing may be written
# into those classes by hand -- maint/spec-to-type.pl --verify compares them
# against the swagger byte for byte (t/spec_to_type.t) -- so this file is what
# proves the methods arrive anyway, and on both shapes.
#
# Fixture-only throughout: none of it needs a daemon, and the assertions are
# about the model rather than about anything an engine answers.

check_live_access();

my $SUMMARY = 'API::Docker::Type::ContainerSummary';
my $INSPECT = 'API::Docker::Type::ContainerInspectResponse';

subtest 'both container shapes carry the same methods' => sub {
  # Written out rather than derived from the role, so that a method quietly
  # disappearing from the role is a failure here and not a shorter list
  # compared against itself.
  my @methods = qw(
    attach changes export get_archive inspect is_running kill logs pause
    put_archive remove resize restart start stat_archive stats stop top
    unpause
  );
  is scalar @methods, 19, 'all nineteen of them are named here';

  for my $class ($SUMMARY, $INSPECT) {
    ok $class->does('API::Docker::Role::Entity::Container'),
      "$class does the container entity role";
    ok $class->does('API::Docker::Role::Entity'),
      "$class does the shared entity role with it";
    my @missing = grep { !$class->can($_) } @methods;
    is_deeply \@missing, [], "$class can every convenience method";
  }
};

subtest 'the generated classes are still the model, not a wrapper around it' => sub {
  plan skip_all => 'fixture-only' if is_live();

  # containers_list/container_inspect (karr k101 follow-up): a real
  # capture -- see t/containers.t.
  my $docker = test_docker(
    'GET /containers/json'          => load_fixture('containers_list'),
    'GET /containers/b20ac7508d80182ba3cd1cbd006ac10c8a15f4f7590fa89c2078d146caf96555/json'
      => load_fixture('container_inspect'),
  );

  my ($c) = @{ $docker->containers->list };
  isa_ok $c, $SUMMARY;
  is $c->id, 'b20ac7508d80182ba3cd1cbd006ac10c8a15f4f7590fa89c2078d146caf96555',
    'the daemon field is on the object itself';
  is $c->image_id,
    'sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b',
    'including one whose Perl name is not its wire name (ImageID, not ImageId)';

  my $full = $docker->containers->inspect(
    'b20ac7508d80182ba3cd1cbd006ac10c8a15f4f7590fa89c2078d146caf96555');
  isa_ok $full, $INSPECT;
  isa_ok $full->state, 'API::Docker::Type::ContainerState',
    'and a nested field is still inflated into its own generated class';
};

# The defect this whole mechanism had to be designed around, and the reason
# API::Docker::Role::Type grew _entity_attribute_index.
#
# API::Docker::Role::Type's BUILDARGS sorts every constructor key into "a
# field of this definition" or "a field the daemon sent that we have not heard
# of", and keeps the second kind in unknown_fields so it can be handed back to
# the engine verbatim. `client` is neither. Without the hook it landed in
# unknown_fields, and to_json then died trying to encode the client object
# into a request body -- measured before the fix:
#
#   encountered object 'API::Docker=HASH(0x...)', but allow_blessed,
#   allow_stringify or TO_JSON/FREEZE method missing
subtest 'the client is an attribute, not a field the daemon sent' => sub {
  plan skip_all => 'fixture-only' if is_live();

  my $docker = test_docker();

  for my $class ($SUMMARY, $INSPECT) {
    my $c = $class->new(
      client   => $docker,
      Id       => 'abc',
      NoSuchField => 'kept',
    );
    is $c->client, $docker, "$class: client reached the attribute";
    is_deeply [ sort keys %{ $c->unknown_fields } ], ['NoSuchField'],
      "$class: it is not filed as an unknown daemon field -- and one that "
      . 'really is unknown still survives beside it';
    is_deeply $c->TO_JSON, { Id => 'abc', NoSuchField => 'kept' },
      "$class: so the client is not offered back to the engine";
    is $c->to_json, '{"Id":"abc","NoSuchField":"kept"}',
      "$class: and encoding a request body from it does not die";
  }
};

subtest 'the client is weak, as it is on every entity' => sub {
  my $c;
  {
    my $docker = test_docker();
    $c = $SUMMARY->new(client => $docker, Id => 'abc');
    ok defined $c->client, 'held while the client is alive';
  }
  ok !defined $c->client,
    'and gone once nothing else holds it -- an entity never keeps the client '
    . 'alive, which is why library code has to';
};

subtest 'a method forwards the entity own id to the resource class' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my %seen;
  my $docker = test_docker(
    'GET /containers/json'            => [ { Id => 'deadbeef', State => 'running' } ],
    'GET /containers/deadbeef/json'   => { Id => 'deadbeef',
      State => { Running => 1, Status => 'running' } },
    'POST /containers/deadbeef/start' => sub { $seen{start}++; undef },
    'POST /containers/deadbeef/stop'  => sub { $seen{stop}++;  undef },
    'DELETE /containers/deadbeef'     => sub { $seen{remove}++; undef },
  );

  my ($c) = @{ $docker->containers->list };
  is $c->start, 1, 'start went through and reported the 204';
  is $c->stop(timeout => 3), 1, 'stop too';
  $c->remove(force => 1);
  is_deeply \%seen, { start => 1, stop => 1, remove => 1 },
    'each reached its own endpoint under the id of the object it was called on';

  # inspect is the one that changes shape underneath the caller.
  my $full = $c->inspect;
  isa_ok $full, $INSPECT,
    'a summary inspects into the inspect class, not into another summary';
};

subtest 'is_running reads whichever of the two shapes it is on' => sub {
  is $SUMMARY->new(State => 'running')->is_running, 1, 'summary: the string';
  is $SUMMARY->new(State => 'exited')->is_running,  0, 'summary: a stopped one';
  is $SUMMARY->new(State => 'RUNNING')->is_running, 1,
    'summary: the comparison is case-insensitive';
  is $SUMMARY->new(Id => 'x')->is_running, 0,
    'summary: no State at all is not running';

  is $INSPECT->new(State => { Running => 1 })->is_running, 1,
    'inspect: the ContainerState object';
  is $INSPECT->new(State => { Running => 0, Status => 'exited' })->is_running, 0,
    'inspect: a stopped one';
  is $INSPECT->new(State => { Status => 'created' })->is_running, 0,
    'inspect: a State that never says Running is not running';
  is $INSPECT->new(Id => 'x')->is_running, 0,
    'inspect: no State at all is not running';
};

# "a method forwards the entity own id to the resource class" above covers
# start/stop/remove/inspect; kill, logs, pause, restart, top, stats and
# unpause were only ever proved with can() (karr k109). Call each and assert
# what actually reached the mock route table.
subtest 'the remaining container methods forward the entity own id too' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my $multiplexed = load_fixture_raw('containers_logs_multiplexed.bin');

  my %seen;
  my $docker = test_docker(
    'GET /containers/json'              => [ { Id => 'deadbeef', State => 'running' } ],
    'POST /containers/deadbeef/kill'    => sub {
      my ($method, $path, %opts) = @_;
      $seen{kill} = $opts{params};
      return undef;
    },
    'GET /containers/deadbeef/logs'     => sub { $multiplexed },
    'POST /containers/deadbeef/pause'   => sub { $seen{pause}++;   return undef },
    'POST /containers/deadbeef/restart' => sub { $seen{restart}++; return undef },
    'GET /containers/deadbeef/top'      => { Titles => [], Processes => [] },
    'GET /containers/deadbeef/stats'    => { cpu_stats => { cpu_usage => { total_usage => 1 } } },
    'POST /containers/deadbeef/unpause' => sub { $seen{unpause}++; return undef },
  );

  my ($c) = @{ $docker->containers->list };

  $c->kill(signal => 'SIGTERM');
  is_deeply $seen{kill}, { signal => 'SIGTERM' },
    "kill reached POST /containers/deadbeef/kill under the entity's own id";

  is_deeply $c->logs, [
    { stream => 'stdout', data => "OUT\n" },
    { stream => 'stderr', data => "ERR\n" },
  ], 'logs reached GET /containers/deadbeef/logs and demultiplexed the frames';

  is $c->pause, 1, 'pause reached POST /containers/deadbeef/pause';
  ok $seen{pause}, 'and was actually requested';

  is $c->restart, 1, 'restart reached POST /containers/deadbeef/restart';
  ok $seen{restart}, 'and was actually requested';

  is_deeply $c->top, { Titles => [], Processes => [] },
    'top reached GET /containers/deadbeef/top';

  is_deeply $c->stats, { cpu_stats => { cpu_usage => { total_usage => 1 } } },
    'stats reached GET /containers/deadbeef/stats';

  is $c->unpause, 1, 'unpause reached POST /containers/deadbeef/unpause';
  ok $seen{unpause}, 'and was actually requested';
};

done_testing;
