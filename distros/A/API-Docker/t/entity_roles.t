#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use API::Docker::Role::Entity::Config;
use API::Docker::Role::Entity::Image;
use API::Docker::Role::Entity::Network;
use API::Docker::Role::Entity::Plugin;
use API::Docker::Role::Entity::Secret;
use API::Docker::Role::Entity::Volume;

# karr k84, the six resources k79 step 6/7 still owed after containers:
# Image, Network, Volume, Plugin, Secret, Config. The convenience methods live
# in API::Docker::Role::Entity::<Resource> and are composed into the generated
# classes the daemon answers with. Nothing may be written into those classes
# by hand -- maint/spec-to-type.pl --verify compares them against the swagger
# byte for byte (t/spec_to_type.t) -- so this file is what proves the methods
# arrive anyway.
#
# t/entity_container.t is the same file for containers, and stays separate:
# containers have nineteen methods and two shapes that disagree in ways worth
# asserting one by one. This file carries the invariants all six share, and
# each resource's own forwarding assertions stay in its own test file
# (t/images.t, t/networks.t, t/volumes.t, t/plugins.t, t/secrets_configs.t).
#
# Fixture-only throughout: none of it needs a daemon, and the assertions are
# about the model rather than about anything an engine answers.

check_live_access();

# Which generated classes each role belongs on, and the field the role
# addresses the resource by. Written out rather than derived from the roles,
# so a class quietly dropping out of a composition loop is a failure here and
# not a shorter list compared against itself.
#
# Two of the six answer list and inspect with two different definitions;
# four answer both with one. Read off spec/v1.51.yaml, not assumed:
#   /images/json      -> [ImageSummary]   /images/{name}/json -> ImageInspect
#   /networks         -> [Network]        /networks/{id}      -> Network
#   /volumes          -> VolumeListResponse{Volumes: [Volume]}
#                                         /volumes/{name}     -> Volume
#   /plugins          -> [Plugin]         /plugins/{name}/json-> Plugin
#   /secrets          -> [Secret]         /secrets/{id}       -> Secret
#   /configs          -> [Config]         /configs/{id}       -> Config
my @RESOURCES = (
  { role    => 'API::Docker::Role::Entity::Image',
    classes => [qw( API::Docker::Type::ImageSummary
                    API::Docker::Type::ImageInspect )],
    key     => 'id',
    methods => [qw( history inspect remove tag )] },
  { role    => 'API::Docker::Role::Entity::Network',
    classes => ['API::Docker::Type::Network'],
    key     => 'id',
    methods => [qw( connect disconnect inspect remove )] },
  { role    => 'API::Docker::Role::Entity::Volume',
    classes => ['API::Docker::Type::Volume'],
    key     => 'name',
    methods => [qw( inspect remove )] },
  { role    => 'API::Docker::Role::Entity::Plugin',
    classes => ['API::Docker::Type::Plugin'],
    key     => 'name',
    methods => [qw( configure disable enable inspect push remove upgrade )] },
  { role    => 'API::Docker::Role::Entity::Secret',
    classes => ['API::Docker::Type::Secret'],
    key     => 'id',
    methods => [qw( inspect remove update version_index )] },
  { role    => 'API::Docker::Role::Entity::Config',
    classes => ['API::Docker::Type::Config'],
    key     => 'id',
    methods => [qw( decoded_data inspect remove update version_index )] },
);

subtest 'every entity role reaches the generated classes of its resource' => sub {
  for my $r (@RESOURCES) {
    for my $class (@{ $r->{classes} }) {
      ok $class->does($r->{role}), "$class does $r->{role}";
      ok $class->does('API::Docker::Role::Entity'),
        "$class does the shared entity role with it";
      my @missing = grep { !$class->can($_) } @{ $r->{methods} };
      is_deeply \@missing, [], "$class can every convenience method";
      ok $class->can($r->{key}),
        "$class has the $r->{key} the role addresses it by";
    }
  }
};

# Moo composes a role into a class the class-wins way, so a generated accessor
# of the same name as a role method keeps its place silently and the method is
# simply missing. The composition block in each role croaks on that at load
# time; this asserts the condition it checks actually holds, which is the part
# a future swagger can break without anyone touching this distribution.
subtest 'no role method is also a daemon field of the class it lands on' => sub {
  for my $r (@RESOURCES) {
    for my $class (@{ $r->{classes} }) {
      my $fields = $class->docker_attributes;
      my @clash = sort grep { $fields->{$_} } @{ $r->{methods} };
      is_deeply \@clash, [],
        "$class declares none of $r->{role}'s method names as a field";
    }
  }
};

# The defect the whole mechanism had to be designed around, and the reason
# API::Docker::Role::Type grew _entity_attribute_index: without the hook the
# client landed in unknown_fields and to_json died trying to encode the client
# object into a request body. Asserted for containers in t/entity_container.t;
# this is the same claim for the other six, because the hook is per-role.
subtest 'the client is an attribute, not a field the daemon sent' => sub {
  plan skip_all => 'fixture-only' if is_live();

  my $docker = test_docker();

  for my $r (@RESOURCES) {
    for my $class (@{ $r->{classes} }) {
      my $obj = $class->new(
        client      => $docker,
        NoSuchField => 'kept',
      );
      is $obj->client, $docker, "$class: client reached the attribute";
      is_deeply [ sort keys %{ $obj->unknown_fields } ], ['NoSuchField'],
        "$class: it is not filed as an unknown daemon field -- and one that "
        . 'really is unknown still survives beside it';
      is_deeply $obj->TO_JSON, { NoSuchField => 'kept' },
        "$class: so the client is not offered back to the engine";
      is $obj->to_json, '{"NoSuchField":"kept"}',
        "$class: and encoding a request body from it does not die";
    }
  }
};

subtest 'the client is weak on every one of them' => sub {
  for my $r (@RESOURCES) {
    for my $class (@{ $r->{classes} }) {
      my $obj;
      {
        my $docker = test_docker();
        $obj = $class->new(client => $docker);
        ok defined $obj->client, "$class: held while the client is alive";
      }
      ok !defined $obj->client,
        "$class: and gone once nothing else holds it -- an entity never keeps "
        . 'the client alive, which is why library code has to';
    }
  }
};

# _wrap goes through from_data, not new. The two entry points of
# API::Docker::Role::Type read their keys differently, and only from_data
# carries the wire-name rule and k83's leniency out to the entity objects --
# so this is a property of the resource classes, asserted through them.
subtest 'list and inspect build through from_data, so a wire name is a wire name'
    => sub {
  plan skip_all => 'fixture-only' if is_live();

  # `id` is the Perl name of the field whose wire name is `Id`. from_data
  # reads wire names only, so a lowercase `id` off an engine stays an unknown
  # field under its own spelling instead of being read as that field -- which
  # is exactly what `new` would have done, and what _wrap used to do.
  my $docker = test_docker(
    'GET /networks' => [ { Id => 'net1', Name => 'bridge', id => 'not-me' } ],
  );

  my ($net) = @{ $docker->networks->list };
  isa_ok $net, 'API::Docker::Type::Network';
  is $net->id, 'net1', 'the wire name Id filled the attribute';
  is $net->unknown_fields->{id}, 'not-me',
    'and a lowercase id stayed an unknown field rather than overwriting it';
  is $net->TO_JSON->{id}, 'not-me', 'so it goes back out under its own name';
};

subtest 'a value that disagrees with the swagger costs its field, not the response'
    => sub {
  plan skip_all => 'fixture-only' if is_live();

  # karr k83, on a resource that is not containers: Volume->status is a
  # HashRef in the swagger. A string there used to take the whole response
  # down; through from_data it costs that one field and is kept verbatim.
  my $docker = test_docker(
    'GET /volumes' => { Volumes => [ {
      Name       => 'my-data',
      Driver     => 'local',
      Mountpoint => '/var/lib/docker/volumes/my-data/_data',
      Status     => 'not-a-hashref',
    } ] },
  );

  my ($vol) = @{ $docker->volumes->list };
  is $vol->name, 'my-data', 'the rest of the response is readable';
  is $vol->status, undef, 'the field the model could not use is unset';
  is $vol->unknown_fields->{Status}, 'not-a-hashref',
    'its raw value is kept under the wire name';
  is $vol->rejected_fields->{Status}, 'status',
    'and named in rejected_fields, so "never sent" stays distinguishable '
    . 'from "sent and refused"';
  is $vol->TO_JSON->{Status}, 'not-a-hashref',
    'TO_JSON writes it back unchanged';

  # new is the other entry point and keeps the strict contract.
  eval { API::Docker::Type::Volume->new(Name => 'x', Status => 'not-a-hashref') };
  ok $@, 'new still croaks on it -- there the value came from the caller';
};

subtest 'version_index reads through the generated ObjectVersion' => sub {
  # The hand-written entities read $self->Version->{Index} out of a raw
  # HashRef. `version` is an API::Docker::Type::ObjectVersion now, so the
  # claim is the same value reached one accessor further in.
  for my $class ('API::Docker::Type::Secret', 'API::Docker::Type::Config') {
    my $obj = $class->new(ID => 'x', Version => { Index => 11 });
    isa_ok $obj->version, 'API::Docker::Type::ObjectVersion',
      "$class: Version inflated and";
    is $obj->version_index, 11, "$class: version_index reaches its index";
    is $class->new(ID => 'x')->version_index, undef,
      "$class: and an object with no Version has none rather than dying";
  }
};

# --- Smoke calls: each role's methods actually invoked, request asserted ---
#
# "every entity role reaches the generated classes of its resource" above
# only proves can() -- that the method exists. None of it calls one, so a
# role method that raised, forwarded the wrong id, or dropped its arguments
# on the floor would not fail a single assertion in this file. These
# subtests call every method of Network, Image and Volume (Container's own
# gaps -- kill/logs/pause/restart/top/stats/unpause -- are in
# t/entity_container.t beside its other forwarding coverage) and assert what
# actually reached the mock route table: the path, and the body where the
# method sends one.

subtest 'network entity methods reach the daemon under its own id' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my %seen;
  my $docker = test_docker(
    'GET /networks/net1'             => sub { $seen{inspect}++; return { Id => 'net1', Name => 'net1' } },
    'DELETE /networks/net1'          => sub { $seen{remove}++; return undef },
    'POST /networks/net1/connect'    => sub {
      my ($method, $path, %opts) = @_;
      $seen{connect} = $opts{body};
      return undef;
    },
    'POST /networks/net1/disconnect' => sub {
      my ($method, $path, %opts) = @_;
      $seen{disconnect} = $opts{body};
      return undef;
    },
  );

  my $network = API::Docker::Type::Network->new(client => $docker, Id => 'net1');

  $network->connect(Container => 'c1');
  is_deeply $seen{connect}, { Container => 'c1' },
    "connect posts the container id under the network's own id";

  $network->disconnect(Container => 'c1', Force => 1);
  is_deeply $seen{disconnect}, { Container => 'c1', Force => \1 },
    'disconnect posts its body too, with Force normalised to a JSON boolean';

  $network->remove;
  ok $seen{remove}, "remove reached DELETE /networks/net1 -- the entity's own id";

  my $fresh = $network->inspect;
  isa_ok $fresh, 'API::Docker::Type::Network';
  ok $seen{inspect}, 'inspect reached GET /networks/net1';
};

subtest 'image entity methods reach the daemon under its own id' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my %seen;
  my $docker = test_docker(
    'GET /images/img1/json'    => sub { $seen{inspect}++; return { Id => 'img1' } },
    'GET /images/img1/history' => sub { $seen{history}++; return []; },
    'POST /images/img1/tag'    => sub {
      my ($method, $path, %opts) = @_;
      $seen{tag} = $opts{params};
      return undef;
    },
    'DELETE /images/img1'      => sub { $seen{remove}++; return []; },
  );

  my $image = API::Docker::Type::ImageSummary->new(client => $docker, Id => 'img1');

  my $full = $image->inspect;
  isa_ok $full, 'API::Docker::Type::ImageInspect',
    'inspect returns the OTHER shape, whatever the invocant was';
  ok $seen{inspect}, "inspect reached GET /images/img1/json -- the entity's own id";

  is_deeply $image->history, [], 'history reached GET /images/img1/history';
  ok $seen{history}, 'and was actually requested';

  $image->tag(repo => 'myrepo/app', tag => 'v1');
  is_deeply $seen{tag}, { repo => 'myrepo/app', tag => 'v1' },
    "tag posts to the image's own id with repo/tag as query params";

  $image->remove(force => 1);
  ok $seen{remove}, "remove reached DELETE /images/img1 -- the entity's own id";
};

subtest 'volume entity methods forward the NAME, not an id -- the one deviation' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  # Volume requires 'name' rather than 'id' (see API::Docker::Role::Entity::Volume
  # /"The entity is addressed by name, not by id"). can() alone cannot tell a
  # method that forwards the right identifier from one that forwards the
  # wrong one -- both satisfy `requires 'name'` -- so this is the one place
  # that deviation is actually exercised: the path itself has to carry the
  # volume's name.
  my %seen;
  my $docker = test_docker(
    'GET /volumes/my-data'    => sub { $seen{inspect}++; return { Name => 'my-data' } },
    'DELETE /volumes/my-data' => sub { $seen{remove}++; return undef },
  );

  my $volume = API::Docker::Type::Volume->new(client => $docker, Name => 'my-data');

  my $fresh = $volume->inspect;
  isa_ok $fresh, 'API::Docker::Type::Volume';
  ok $seen{inspect}, "inspect reached GET /volumes/my-data -- the volume's name";

  $volume->remove(force => 1);
  ok $seen{remove}, "remove reached DELETE /volumes/my-data -- the volume's name";
};

done_testing;
