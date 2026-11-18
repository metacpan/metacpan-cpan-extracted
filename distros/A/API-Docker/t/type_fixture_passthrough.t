#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use API::Docker::Type::ContainerInspectResponse;
use API::Docker::Type::ContainerSummary;
use API::Docker::Type::ImageSummary;
use API::Docker::Type::Network;
use API::Docker::Type::Secret;
use API::Docker::Type::SystemInfo;
use API::Docker::Type::SystemVersion;
use API::Docker::Type::VolumeListResponse;

# karr k81: every fixture under t/fixtures/*.json is captured output from a
# real daemon (skill api-docker-core), not hand-rolled -- so feeding each one
# through the generated class its endpoint returns measures the type model's
# passthrough invariant against reality rather than against a test its own
# author wrote. TO_JSON of the inflated object must carry every key the
# fixture had: nothing dropped, nothing renamed.
#
# karr k101: that claim did not hold. Seven of these eight fixtures were
# hand-typed -- a hex-looking Id ending "...defg" (g/h are not hex),
# a ParentId padded out to 64 characters, timestamps rounded to the hour,
# invented names ("my-container", "test-host") -- and every one of them
# inflated with empty unknown_fields/rejected_fields because they were
# written against the open swagger rather than against a socket.
# images_list.json, networks_list.json, system_info.json and
# system_version.json were the first four recaptured; the "Measured"/
# "Captured" comment at each fixture's load_fixture() call site (t/images.t,
# t/networks.t, t/system.t, t/version.t) names which engine and API version
# each came from. containers_list.json, container_inspect.json and
# volumes_list.json stayed hand-rolled through that pass: neither engine
# reachable from this machine had a container or a volume to capture from
# (`containers/json?all=1` and `volumes` both answered empty, on Docker
# 29.7.2 and on Podman 5.8.4), and creating one only to capture it was
# outside what that task could do.
#
# That gap closed 2026-08-29 (karr k101 follow-up), under explicit
# maintainer sign-off for a controlled mutation: a disposable container and
# a disposable volume, both named apidocker-fixture-probe-<random>, created
# on Docker 29.7.2 (API 1.55) from the alpine:3 image already cached on that
# engine, captured through `GET /containers/json?all=1`,
# `GET /containers/{id}/json` and `GET /volumes` (each filtered to the one
# resource so the fixture stays small and deterministic), then removed --
# both confirmed gone (404 on inspect, absent from both list endpoints)
# before the run that captured them ended. See the load_fixture() call
# sites in t/containers.t and t/volumes.t for the note. secrets_list.json
# (2d5a50c) was already a real capture and stays as it was. All eight
# fixtures under t/fixtures/*.json are now real captures.
#
# karr k93: at every depth, and with one named exception. The comparison used
# to be `keys %$item` -- the top level of each object only -- which is why the
# two nulls the fixtures actually contain sat unexamined below it. A known
# field an engine sent as an explicit null is read as unset and loses its key,
# because the daemon cannot tell an explicit null from an absent field in
# either direction (measured, see API::Docker::Role::Type/"A null on a known
# field is read as unset"). That is correct behaviour, so this test names it
# and asserts it rather than exempting it quietly.
#
# It asserts fixture content, so it opts out of live mode the way every
# content-asserting test in this suite does (skill api-docker-core): none of
# it calls test_docker(), so it never reaches the route table load_fixture()
# reads the JSON straight off disk either way -- but the point under test is
# the shape of these specific captured files, not of whatever a live daemon
# happens to hold right now.
#
# Inflated through from_data, which is the entry point a daemon response goes
# through: it reads the swagger's wire names and nothing else, so a fixture
# key the model has not heard of keeps its own spelling rather than being
# read as the Perl name of one it has (karr k85).
plan skip_all => 'asserts captured fixture content, not live daemon state'
  if is_live();

# Fixture basename => [ generated class, sub that turns the decoded fixture
# into the list of objects to inflate ]. containers_list/networks_list/
# images_list/secrets_list are bare arrays in the swagger; volumes_list is
# the one wrapper (VolumeListResponse, holding Volumes + Warnings), and
# inflating the wrapper itself exercises the nested Volume objects too.
my @CASES = (
  [ container_inspect => 'API::Docker::Type::ContainerInspectResponse',
    sub { $_[0] } ],
  [ containers_list => 'API::Docker::Type::ContainerSummary',
    sub { @{ $_[0] } } ],
  [ networks_list => 'API::Docker::Type::Network',
    sub { @{ $_[0] } } ],
  [ volumes_list => 'API::Docker::Type::VolumeListResponse',
    sub { $_[0] } ],
  [ system_info => 'API::Docker::Type::SystemInfo',
    sub { $_[0] } ],
  [ system_version => 'API::Docker::Type::SystemVersion',
    sub { $_[0] } ],
  [ images_list => 'API::Docker::Type::ImageSummary',
    sub { @{ $_[0] } } ],
  [ secrets_list => 'API::Docker::Type::Secret',
    sub { @{ $_[0] } } ],
);

# The whole list of keys the round trip is allowed to lose, written out here
# rather than derived from what the run happens to produce -- a set the test
# computes from the model is a set the test cannot be wrong about. Every
# entry is a known field the engine itself sent as an explicit null; the
# assertion at the end is is_deeply against this, so a new one appearing is
# red, and so is one of these ceasing to drop -- which is what changing the
# null rule would look like. Recaptured 2026-08-28 (karr k101) against
# Docker 29.7.2 (API 1.55) for networks_list/system_info and Podman 5.8.4
# (compat API 1.44) for images_list -- see the load_fixture() call sites in
# t/images.t, t/networks.t and t/system.t for detail. Recaptured
# 2026-08-29 (karr k101 follow-up) against Docker 29.7.2 (API 1.55) for
# containers_list/container_inspect/volumes_list -- see t/containers.t and
# t/volumes.t:
#   images_list[2..4]/Labels     -- Podman answers Labels: null on a tagged
#                                    image that carries no label, where
#                                    Docker answers {}
#   networks_list[0,1]/IPAM/Config,
#   networks_list[0..2]/IPAM/Options
#                                 -- Docker's "none" and "host" networks
#                                    carry no IPAM config at all; every one
#                                    of the three ships IPAM.Options: null
#   secrets_list[1]/Spec/Labels   -- unchanged, predates this recapture
#   system_info[0]/GenericResources,
#   system_info[0]/Plugins/Authorization,
#   system_info[0]/Swarm/RemoteManagers,
#   system_info[0]/Warnings
#                                 -- this engine has none of the four to
#                                    report and sends null rather than [] or
#                                    {} for each
#   containers_list[0] and container_inspect[0]'s
#     NetworkSettings/Networks/bridge/
#     {Aliases,DNSNames,DriverOpts,IPAMConfig,Links}
#                                 -- the probe container is attached to
#                                    "bridge" with no non-default network
#                                    config, so libnetwork answers null on
#                                    all five per-endpoint fields, on both
#                                    the summary and the inspect shape
#   container_inspect[0]/Config/Entrypoint,
#   container_inspect[0]/Config/Volumes
#                                 -- alpine:3 sets neither, and the probe
#                                    container did not override them
#   container_inspect[0]/ExecIDs -- no `exec` was ever run against it
#   container_inspect[0]/HostConfig/
#     {BlkioWeightDevice,BlkioDeviceReadBps,BlkioDeviceWriteBps,
#      BlkioDeviceReadIOps,BlkioDeviceWriteIOps,CapAdd,CapDrop,Devices,
#      DeviceCgroupRules,DeviceRequests,Dns,DnsOptions,DnsSearch,
#      ExtraHosts,GroupAdd,Links,MemorySwappiness,OomKillDisable,
#      PidsLimit,SecurityOpt,Ulimits,VolumesFrom}
#                                 -- every optional resource limit and
#                                    legacy-linking knob the probe container
#                                    was created without; the engine answers
#                                    "unset" as null rather than as an empty
#                                    array or a zero value, for each
#   volumes_list[0]/Volumes[0]/Options
#                                 -- the probe volume was created without
#                                    driver-specific options
#   volumes_list[0]/Warnings     -- no warnings for this request
my @EXPECTED_NULL_DROPS = (
  'container_inspect[0]/Config/Entrypoint',
  'container_inspect[0]/Config/Volumes',
  'container_inspect[0]/ExecIDs',
  'container_inspect[0]/HostConfig/BlkioDeviceReadBps',
  'container_inspect[0]/HostConfig/BlkioDeviceReadIOps',
  'container_inspect[0]/HostConfig/BlkioDeviceWriteBps',
  'container_inspect[0]/HostConfig/BlkioDeviceWriteIOps',
  'container_inspect[0]/HostConfig/BlkioWeightDevice',
  'container_inspect[0]/HostConfig/CapAdd',
  'container_inspect[0]/HostConfig/CapDrop',
  'container_inspect[0]/HostConfig/DeviceCgroupRules',
  'container_inspect[0]/HostConfig/DeviceRequests',
  'container_inspect[0]/HostConfig/Devices',
  'container_inspect[0]/HostConfig/Dns',
  'container_inspect[0]/HostConfig/DnsOptions',
  'container_inspect[0]/HostConfig/DnsSearch',
  'container_inspect[0]/HostConfig/ExtraHosts',
  'container_inspect[0]/HostConfig/GroupAdd',
  'container_inspect[0]/HostConfig/Links',
  'container_inspect[0]/HostConfig/MemorySwappiness',
  'container_inspect[0]/HostConfig/OomKillDisable',
  'container_inspect[0]/HostConfig/PidsLimit',
  'container_inspect[0]/HostConfig/SecurityOpt',
  'container_inspect[0]/HostConfig/Ulimits',
  'container_inspect[0]/HostConfig/VolumesFrom',
  'container_inspect[0]/NetworkSettings/Networks/bridge/Aliases',
  'container_inspect[0]/NetworkSettings/Networks/bridge/DNSNames',
  'container_inspect[0]/NetworkSettings/Networks/bridge/DriverOpts',
  'container_inspect[0]/NetworkSettings/Networks/bridge/IPAMConfig',
  'container_inspect[0]/NetworkSettings/Networks/bridge/Links',
  'containers_list[0]/NetworkSettings/Networks/bridge/Aliases',
  'containers_list[0]/NetworkSettings/Networks/bridge/DNSNames',
  'containers_list[0]/NetworkSettings/Networks/bridge/DriverOpts',
  'containers_list[0]/NetworkSettings/Networks/bridge/IPAMConfig',
  'containers_list[0]/NetworkSettings/Networks/bridge/Links',
  'images_list[2]/Labels',
  'images_list[3]/Labels',
  'images_list[4]/Labels',
  'networks_list[0]/IPAM/Config',
  'networks_list[0]/IPAM/Options',
  'networks_list[1]/IPAM/Config',
  'networks_list[1]/IPAM/Options',
  'networks_list[2]/IPAM/Options',
  'secrets_list[1]/Spec/Labels',
  'system_info[0]/GenericResources',
  'system_info[0]/Plugins/Authorization',
  'system_info[0]/Swarm/RemoteManagers',
  'system_info[0]/Warnings',
  'volumes_list[0]/Volumes[0]/Options',
  'volumes_list[0]/Warnings',
);

# --- the comparison ---------------------------------------------------------
#
# Walks the fixture and TO_JSON's output together and reports every fixture
# key that has no counterpart in the output. "Governance" travels down with
# the walk: at each node it says which generated class -- if any -- owns the
# keys of the hash sitting there, because the null exemption applies to a
# field that class KNOWS and to nothing else. Three shapes, taken from the
# registry's own type descriptors:
#
#   object  keys are the fields of a generated class
#   map     keys are the caller's data (the additionalProperties shape), so
#           no key of it is ever a known field, and the values are governed
#           by the inner descriptor
#   array   every element is governed by the inner descriptor
#
# undef governance is a subtree the model does not model -- the value of an
# unknown field, or of a map of scalars. Nothing there is a known field, so
# nothing there may be lost, which is the asymmetry under test.

my %WIRE_INDEX;

sub wire_index {
  my ($class) = @_;
  return $WIRE_INDEX{$class} ||= do {
    my $reg = $class->docker_attributes;
    +{ map { ($reg->{$_}{wire} => $_) } keys %$reg };
  };
}

sub gov_of_descriptor {
  my ($d) = @_;
  return undef unless $d;
  return { kind => 'object', class => $d->{class} } if $d->{kind} eq 'object';
  return { kind => 'array', inner => gov_of_descriptor($d->{inner}) }
    if $d->{kind} eq 'array';
  return { kind => 'map', inner => gov_of_descriptor($d->{inner}) }
    if $d->{kind} eq 'hash';
  return undef;
}

sub gov_of_field {
  my ($gov, $key) = @_;
  return $gov->{inner} if $gov && $gov->{kind} eq 'map';
  return undef unless $gov && $gov->{kind} eq 'object';
  my $attr = wire_index($gov->{class})->{$key};
  return undef unless defined $attr;
  return gov_of_descriptor($gov->{class}->docker_attributes->{$attr}{type});
}

# Returns two lists: keys that went missing, and keys that went missing under
# the null rule. The second is returned rather than swallowed so the caller
# has to say out loud which drops it expects.
sub compare {
  my ($data, $out, $gov, $path, $lost, $nulled) = @_;
  if (ref $data eq 'HASH') {
    unless (ref $out eq 'HASH') {
      push @$lost, "$path (an object came back as " . (ref($out) || 'a plain value') . ')';
      return;
    }
    my $known = $gov && $gov->{kind} eq 'object' ? wire_index($gov->{class}) : {};
    for my $key (sort keys %$data) {
      unless (exists $out->{$key}) {
        # The one exemption, and only where the model really does know the
        # field: a null under a caller's own key, or under a name the model
        # never heard of, has no zero value we could read it as and must
        # survive like any other value.
        if (!defined $data->{$key} && $known->{$key}) {
          push @$nulled, "$path/$key";
          next;
        }
        push @$lost, "$path/$key";
        next;
      }
      compare($data->{$key}, $out->{$key}, gov_of_field($gov, $key),
        "$path/$key", $lost, $nulled);
    }
    return;
  }
  if (ref $data eq 'ARRAY') {
    unless (ref $out eq 'ARRAY') {
      push @$lost, "$path (an array came back as " . (ref($out) || 'a plain value') . ')';
      return;
    }
    my $inner = $gov && $gov->{kind} eq 'array' ? $gov->{inner} : undef;
    compare($data->[$_], $out->[$_], $inner, $path . '[' . $_ . ']', $lost, $nulled)
      for 0 .. $#$data;
    return;
  }
  return;
}

my @NULLED;

for my $case (@CASES) {
  my ($fixture, $class, $items_of) = @$case;
  my $data  = load_fixture($fixture);
  my @items = $items_of->($data);
  cmp_ok scalar(@items), '>=', 1,
    "$fixture: at least one object to round-trip"
    or next;

  for my $i (0 .. $#items) {
    my $item = $items[$i];
    my $out  = $class->from_data($item)->TO_JSON;
    my (@lost, @nulled);
    compare($item, $out, { kind => 'object', class => $class },
      "$fixture\[$i\]", \@lost, \@nulled);
    is_deeply \@lost, [],
      "$fixture\[$i\]: $class round-trips every key the daemon sent, "
      . 'at every depth';
    push @NULLED, @nulled;
  }
}

is_deeply [ sort @NULLED ], [ sort @EXPECTED_NULL_DROPS ],
  'the only keys the fixtures lose are the two known fields the engine sent '
  . 'as an explicit null, and both of them do lose theirs';

subtest 'the null rule, stated rather than exempted' => sub {
  # The rule the loop above encodes, measured directly on one object so that
  # the three shapes sit side by side. Measured 2026-08-28 against Podman
  # 5.8.4 (API 1.44): POST /containers/create answers {}, {"Image":null} and
  # {"Image":""} with byte-identical errors, so the daemon cannot tell an
  # explicit null from an absent field -- collapsing the two costs no
  # meaning. What we cannot type, we cannot collapse (karr k93).
  my $n = API::Docker::Type::Network->from_data({
    Name    => 'n',
    Options => { 'com.docker.x' => undef },
    IPAM    => { Driver => 'default', Options => undef, FutureNested => undef },
  });
  my $out = $n->TO_JSON;

  ok !exists $out->{IPAM}{Options},
    'a known field sent as null is read as unset, and its key does not come back';
  is $n->ipam->options, undef, 'the attribute is simply unset';
  is_deeply $n->ipam->unknown_fields, { FutureNested => undef },
    'it is not filed as unknown either -- only the field we cannot type is';
  is_deeply $n->ipam->rejected_fields, {},
    'and not as rejected: a null is not a value that failed to fit';

  ok exists $out->{IPAM}{FutureNested},
    'a field the model does not know keeps its null: with no declared type '
    . 'there is no zero value to read it as';
  is $out->{IPAM}{FutureNested}, undef, 'and the null itself is what comes back';

  ok exists $out->{Options}{'com.docker.x'},
    "a null under a key the caller chose is that caller's value and stays";
  is $out->{Options}{'com.docker.x'}, undef, 'null and all';
};

subtest 'the deepened comparison sees what the flat one could not' => sub {
  # What this test could not do before k93, shown rather than asserted: a
  # nested key going missing for a reason the null rule does not cover. The
  # real fixture and its real TO_JSON output are used, and one nested key --
  # IPAM/Driver, a plain string, so nothing about it is a null -- is removed
  # from the output to stand in for a regression that dropped it.
  my $item = load_fixture('networks_list')->[0];
  my $out  = API::Docker::Type::Network->from_data($item)->TO_JSON;
  is $item->{IPAM}{Driver}, 'default',
    'the key about to be removed is a plain string, not a null';

  my %broken = %$out;
  $broken{IPAM} = { %{ $out->{IPAM} } };
  delete $broken{IPAM}{Driver};

  my (@lost, @nulled);
  compare($item, \%broken, { kind => 'object', class => 'API::Docker::Type::Network' },
    'networks_list[0]', \@lost, \@nulled);
  is_deeply \@lost, ['networks_list[0]/IPAM/Driver'],
    'the deepened comparison reports the lost nested key';
  is_deeply [ sort @nulled ],
    [ 'networks_list[0]/IPAM/Config', 'networks_list[0]/IPAM/Options' ],
    'and still counts the nested nulls as the documented exemption, not as a loss';

  # The comparison this file used to make, on the same broken output.
  my @flat = grep { !exists $broken{$_} } keys %$item;
  is_deeply \@flat, [],
    'while comparing top-level keys only finds nothing at all -- which is '
    . 'why the two fixture nulls went unexamined for as long as they did';
};

subtest 'the unknown-field regression this ticket exists to pin down' => sub {
  # This used to be pinned on VirtualSize: in spec/v1.41.yaml, gone from
  # spec/v1.44.yaml onward, with a fixture engine that still sent it. Recaptured
  # 2026-08-28 (karr k101) from Podman 5.8.4 (compat API 1.44) -- neither engine
  # on this machine sends VirtualSize any more (Docker is on 29.7.2 / API 1.55),
  # so a captured fixture cannot demonstrate the defect with that field. Podman's
  # compat layer supplies a live replacement instead: GET /images/json answers
  # with Digest/History/Dangling (untagged images) or Digest/History/Names
  # (tagged ones) alongside the swagger's own fields, and ImageSummary models
  # none of them. The model still forwards them verbatim rather than dropping
  # them -- the specific case the loop above proves in general but that
  # "tidying" the model by discarding unrecognised fields would break first, so
  # it gets its own assertion here too. Derived from the fixture itself via
  # wire_index rather than hardcoded, so a future recapture that adds or drops
  # one of Podman's extensions does not go stale here.
  my $data = load_fixture('images_list');
  ok scalar(@$data), 'images_list fixture has objects to check'
    or return;

  my $known = wire_index('API::Docker::Type::ImageSummary');

  for my $item (@$data) {
    my @unmodeled = sort grep { !exists $known->{$_} } keys %$item;
    ok scalar(@unmodeled),
      "$item->{Id}: the fixture has at least one field the model does not know"
      or next;

    my $obj = API::Docker::Type::ImageSummary->from_data($item);
    my $out = $obj->TO_JSON;
    for my $field (@unmodeled) {
      ok exists $obj->unknown_fields->{$field},
        "$item->{Id}: $field is not in the model, so it is filed as unknown "
        . 'rather than silently discarded';
      is_deeply $out->{$field}, $item->{$field},
        "$item->{Id}: and $field reaches TO_JSON unchanged";
    }
  }
};

done_testing;
