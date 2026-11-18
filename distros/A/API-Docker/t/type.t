#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use API::Docker::Role::Entity::Container;
use API::Docker::Type::ContainerConfig;
use API::Docker::Type::ContainerInspectResponse;
use API::Docker::Type::ContainerSummary;
use API::Docker::Type::HostConfig;
use API::Docker::Type::Mount;
use API::Docker::Type::Network;
use API::Docker::Type::Port;
use API::Docker::Type::Resources;
use API::Docker::Type::VolumeCreateOptions;

# The generated type model: API::Docker::Type's DSL, the attribute registry
# it writes, and serialisation in both directions.
#
# Nothing here opens a socket or reaches a daemon, in either mode -- these
# are pure objects. The values come from spec/v1.51.yaml, which is Docker's
# published swagger checked in verbatim; maint/spec-drift-check.pl is what
# proves a class still matches it, and this file is what proves the three
# invariants the model must never break.

my $json = JSON::MaybeXS->new(canonical => 1);

# ---------------------------------------------------------------------------
# INVARIANT 1: the keys of an additionalProperties field are the caller's
# data and are NEVER translated. Getting this wrong silently rewrites what
# the user typed, and a label is the sort of thing a deployment is keyed on.
# ---------------------------------------------------------------------------

subtest 'caller-data keys survive in both directions' => sub {
  my %labels = (
    'com.example.Some-Label' => 'yes',
    'org.opencontainers.image.source' => 'https://example.invalid/x',
    'UPPER_and_lower'        => '1',
    'a.b.c.d'                => '2',
  );
  my $mount = API::Docker::Type::Mount->from_data({
    Target        => '/data',
    VolumeOptions => { Labels => { %labels } },
  });
  is_deeply($mount->volume_options->labels, { %labels },
    'label keys reach the object exactly as they were written');
  is_deeply($mount->TO_JSON->{VolumeOptions}{Labels}, { %labels },
    'and come back out of TO_JSON unchanged');

  my $hc = API::Docker::Type::HostConfig->from_data({
    Sysctls      => { 'net.ipv4.ip_forward' => '1' },
    StorageOpt   => { size => '120G' },
    Tmpfs        => { '/run' => 'rw,noexec,nosuid,size=65536k' },
    Annotations  => { 'com.example.Some-Label' => 'x' },
    PortBindings => {
      '80/tcp'   => [ { HostIp => '0.0.0.0', HostPort => '8080' } ],
      '53/udp'   => [ { HostIp => '0.0.0.0', HostPort => '53' } ],
      '2377/tcp' => undef,
    },
  });
  my $out = $hc->TO_JSON;
  is_deeply([ sort keys %{ $out->{Sysctls} } ], ['net.ipv4.ip_forward'],
    'a dotted sysctl name is not touched');
  is_deeply([ sort keys %{ $out->{StorageOpt} } ], ['size'],
    'a storage driver option name is not touched');
  is_deeply([ sort keys %{ $out->{Tmpfs} } ], ['/run'],
    'a tmpfs mount path is not touched');
  is_deeply([ sort keys %{ $out->{Annotations} } ], ['com.example.Some-Label'],
    'an annotation name is not touched');
  is_deeply([ sort keys %{ $out->{PortBindings} } ], [ '2377/tcp', '53/udp', '80/tcp' ],
    'port keys keep their <port>/<protocol> form');
  is($out->{PortBindings}{'80/tcp'}[0]{HostPort}, '8080',
    'the values of a caller-keyed hash are still typed and inflated');
  ok(!exists $out->{PortBindings}{port_bindings}
       && !exists $out->{PortBindings}{'80_tcp'},
    'nothing invented a snake_case spelling of a caller key');

  # The invariant names ten fields and the block above exercises six. These
  # are the other four: a generator that misread one of them as structure
  # rather than as caller data would show up nowhere else.
  my $cc = API::Docker::Type::ContainerConfig->from_data({
    ExposedPorts => { '80/tcp' => {}, '53/udp' => {} },
    Volumes      => { '/var/lib/Some-App' => {} },
  });
  is_deeply([ sort keys %{ $cc->TO_JSON->{ExposedPorts} } ], [ '53/udp', '80/tcp' ],
    'an exposed port keeps its <port>/<protocol> form');
  is_deeply([ sort keys %{ $cc->TO_JSON->{Volumes} } ], ['/var/lib/Some-App'],
    'a volume path is not touched');

  my $vco = API::Docker::Type::VolumeCreateOptions->from_data({
    DriverOpts => { 'com.example.Some-Opt' => 'x', type => 'nfs' },
  });
  is_deeply([ sort keys %{ $vco->TO_JSON->{DriverOpts} } ],
    [ 'com.example.Some-Opt', 'type' ],
    'a volume driver option name is not touched, not even one that spells '
      . 'a Perl attribute name of some other class');

  my $net = API::Docker::Type::Network->from_data({
    Options => { 'com.docker.network.bridge.name' => 'br0' },
  });
  is_deeply([ sort keys %{ $net->TO_JSON->{Options} } ],
    ['com.docker.network.bridge.name'], 'a network option name is not touched');
};

# The block above never actually exercises the coercion sub that runs a
# hash-typed field's additionalProperties keys through _coerce_for's hash
# branch (Type.pm): Labels et al are Hash<Str,Str>, whose scalar Str inner
# needs no coercion, so _coerce_for returns undef for it and the hashref is
# never touched by anything -- a coercion bug there would go uncaught no
# matter what the keys look like. And PortBindings above, which IS of that
# shape (its inner is an array of typed PortBinding objects, so a coerce sub
# does run), is only ever given lowercase keys ('2377/tcp', '53/udp',
# '80/tcp'), so a coercion that silently lower-cased every key on that path
# would still leave this file green. Use PortBindings again, this time with
# a key a lowercasing bug would visibly rewrite.
subtest 'a mixed-case additionalProperties key survives the hash coercion branch'
    => sub {
  my $hc = API::Docker::Type::HostConfig->from_data({
    PortBindings => {
      '80/TCP' => [ { HostIp => '0.0.0.0', HostPort => '8080' } ],
    },
  });
  is_deeply([ keys %{ $hc->port_bindings } ], ['80/TCP'],
    'the mixed-case key survives the coercion that inflates its values');
  is_deeply([ keys %{ $hc->TO_JSON->{PortBindings} } ], ['80/TCP'],
    'and comes back out of TO_JSON exactly as written');
};

# ---------------------------------------------------------------------------
# INVARIANT 2: a field the model has never heard of goes through unchanged.
# A caller whose engine is newer than spec/v1.51.yaml must still reach the
# daemon; dropping what we do not recognise would cost this distribution the
# property that a newer engine works on day one.
# ---------------------------------------------------------------------------

subtest 'an unknown field goes in and comes out unchanged' => sub {
  my %newer = (
    FieldFromANewerEngine => 'scalar',
    NestedNewThing        => { a => [ 1, 2, { b => 'c' } ] },
    lowercase_new_thing   => 42,
  );
  my $hc = API::Docker::Type::HostConfig->from_data({ Privileged => JSON->true, %newer });
  is_deeply($hc->unknown_fields, { %newer },
    'everything unrecognised is kept verbatim, under its own name');
  my $out = $hc->TO_JSON;
  is_deeply({ map { ($_ => $out->{$_}) } keys %newer }, { %newer },
    'and is written back out byte for byte');
  is($out->{Privileged}, JSON->true, 'the fields we do know still translate');

  my $round = API::Docker::Type::HostConfig->from_data($out);
  is($json->encode($round->TO_JSON), $json->encode($out),
    'a second pass through the model changes nothing');

  my $unknown_only = API::Docker::Type::Mount->from_data({ Whatever => 1 });
  is_deeply($unknown_only->TO_JSON, { Whatever => 1 },
    'a class that recognises nothing still forwards everything');
};

# ---------------------------------------------------------------------------
# INVARIANT 3: `since` is documentation. Nothing checks it, warns about it
# or drops a field because of it -- we are not the authority on what an
# engine can do (karr k79, decision 2).
# ---------------------------------------------------------------------------

subtest 'since is inert at runtime' => sub {
  my $reg = API::Docker::Type::Mount->docker_attributes;
  is($reg->{image_options}{since}, '1.51',
    'the registry records which spec first carried the field');
  is($reg->{target}{since}, undef,
    'a field already in the oldest spec we hold carries no since');

  my $warned = '';
  local $SIG{__WARN__} = sub { $warned .= $_[0] };
  my $mount = API::Docker::Type::Mount->from_data({
    Target       => '/data',
    ImageOptions => { Subpath => 'dir/sub' },
  });
  is($warned, '', 'setting a field newer than any engine we know warns about nothing');
  is($mount->image_options->subpath, 'dir/sub', 'and the value is kept');
  is_deeply($mount->TO_JSON->{ImageOptions}, { Subpath => 'dir/sub' },
    'and it goes to the daemon; the engine decides, not us');

  my $bind = API::Docker::Type::Mount::BindOptions->new(create_mountpoint => 1);
  is_deeply($bind->TO_JSON, { CreateMountpoint => JSON->true },
    'a 1.44 field on a 1.41 engine is still sent -- Podman serves fields its '
      . 'announced version does not promise, and refuses ones it does');
};

# ---------------------------------------------------------------------------
# The wire name is derived from the Perl name, and the spec's spelling wins
# ---------------------------------------------------------------------------

subtest 'wire names' => sub {
  my $reg = API::Docker::Type::Resources->docker_attributes;
  is($reg->{cpu_shares}{wire},  'CpuShares',  'port_bindings-style derivation');
  is($reg->{nano_cpus}{wire},   'NanoCpus',   'derivation covers most fields');
  is($reg->{oom_kill_disable}{wire}, 'OomKillDisable', 'and multi-word ones');
  is($reg->{kernel_memory_tcp}{wire}, 'KernelMemoryTCP',
    'a spelling the derivation cannot reach is declared explicitly');
  is($reg->{io_maximum_iops}{wire}, 'IOMaximumIOps', 'likewise IOMaximumIOps');
  is($reg->{blkio_device_read_iops}{wire}, 'BlkioDeviceReadIOps',
    'likewise BlkioDeviceReadIOps');
  is(API::Docker::Type::Port->docker_attributes->{ip}{wire}, 'IP',
    'and a two-letter all-caps name');
  is(API::Docker::Type::HostConfig->docker_attributes->{uts_mode}{wire}, 'UTSMode',
    'and UTSMode');

  my $r = API::Docker::Type::Resources->new(
    kernel_memory_tcp => 1024, io_maximum_iops => 7);
  is_deeply($r->TO_JSON, { KernelMemoryTCP => 1024, IOMaximumIOps => 7 },
    'the explicit spelling is what goes on the wire');
  my $back = API::Docker::Type::Resources->from_data({ KernelMemoryTCP => 1024 });
  is($back->kernel_memory_tcp, 1024, 'and what is read back off it');
  is_deeply($back->unknown_fields, {},
    'a wire name the registry knows is never mistaken for an unknown field');
};

# ---------------------------------------------------------------------------
# Booleans: Docker tells an absent flag apart from a false one
# ---------------------------------------------------------------------------

subtest 'booleans' => sub {
  for my $false (JSON->false, \0, 'false', 'FALSE', 0, '') {
    my $m = API::Docker::Type::Mount->new(read_only => $false);
    is($m->TO_JSON->{ReadOnly}, JSON->false,
      'false-ish value ' . (ref $false ? ref $false : "'$false'") . ' serialises to JSON false');
  }
  for my $true (JSON->true, \1, 'true', 1, 'yes') {
    my $m = API::Docker::Type::Mount->new(read_only => $true);
    is($m->TO_JSON->{ReadOnly}, JSON->true,
      'true-ish value ' . (ref $true ? ref $true : "'$true'") . ' serialises to JSON true');
  }
  my $unset = API::Docker::Type::Mount->new(target => '/x');
  ok(!exists $unset->TO_JSON->{ReadOnly},
    'a Bool that was never set is absent, not false');
  my $explicit = API::Docker::Type::Mount->new(target => '/x', read_only => 0);
  ok(exists $explicit->TO_JSON->{ReadOnly},
    'a Bool explicitly set to false is present and false');
  is($json->encode($explicit->TO_JSON), '{"ReadOnly":false,"Target":"/x"}',
    'and encodes as JSON false, never as 1 or the empty string');
  like(
    do { local $@; eval { API::Docker::Type::Mount->new(read_only => [1]) }; $@ },
    qr/Bool wants a scalar/,
    'something that cannot mean true or false croaks instead of being guessed at');
};

# ---------------------------------------------------------------------------
# Nesting, arrays of objects, and the allOf inheritance
# ---------------------------------------------------------------------------

subtest 'nested objects and arrays' => sub {
  my $hc = API::Docker::Type::HostConfig->from_data({
    RestartPolicy       => { Name => 'on-failure', MaximumRetryCount => 3 },
    LogConfig           => { Type => 'json-file', Config => { 'max-size' => '10m' } },
    Mounts              => [ { Target => '/data', Type => 'volume' } ],
    Ulimits             => [ { Name => 'nofile', Soft => 1024, Hard => 2048 } ],
    BlkioDeviceReadIOps => [ { Path => '/dev/sda', Rate => 100 } ],
    Devices             => [ { PathOnHost => '/dev/x', PathInContainer => '/dev/x' } ],
    ConsoleSize         => [ 80, 64 ],
  });
  isa_ok($hc->restart_policy, 'API::Docker::Type::RestartPolicy');
  isa_ok($hc->log_config,     'API::Docker::Type::HostConfig::LogConfig');
  isa_ok($hc->mounts->[0],    'API::Docker::Type::Mount');
  isa_ok($hc->ulimits->[0],   'API::Docker::Type::Resources::Ulimit');
  isa_ok($hc->blkio_device_read_iops->[0], 'API::Docker::Type::ThrottleDevice');
  isa_ok($hc->devices->[0],   'API::Docker::Type::DeviceMapping');
  is($hc->ulimits->[0]->soft, 1024, 'an inline array element inflates');
  is_deeply($hc->console_size, [ 80, 64 ], 'an array of scalars stays an array of scalars');

  my $mount = API::Docker::Type::Mount->from_data({
    TmpfsOptions => { Options => [ ['noexec'], [ 'size', '64m' ] ] },
  });
  is_deeply($mount->tmpfs_options->options, [ ['noexec'], [ 'size', '64m' ] ],
    'an array of arrays of strings survives');

  my $built = API::Docker::Type::HostConfig->new(
    restart_policy => API::Docker::Type::RestartPolicy->new(name => 'always'),
  );
  is_deeply($built->TO_JSON, { RestartPolicy => { Name => 'always' } },
    'an object built by hand serialises the same way an inflated one does');
};

subtest 'allOf becomes inheritance' => sub {
  ok(API::Docker::Type::HostConfig->isa('API::Docker::Type::Resources'),
    'HostConfig is a Resources, because the swagger says allOf [ $ref Resources, ... ]');
  my $order = API::Docker::Type::HostConfig->docker_attribute_order;
  is(scalar @$order, 70, 'HostConfig carries 31 inherited plus 39 of its own');
  is($order->[0], 'cpu_shares', 'the inherited fields come first, as the allOf lists them');
  is($order->[31], 'binds', 'and the class own fields follow in spec order');
  my $hc = API::Docker::Type::HostConfig->from_data({ CpuShares => 512, Binds => ['/a:/b'] });
  is($hc->cpu_shares, 512, 'an inherited field inflates on the child');
  is_deeply($hc->TO_JSON, { CpuShares => 512, Binds => ['/a:/b'] },
    'and serialises flat, the way it sits on the wire');
  is(scalar @{ API::Docker::Type::Resources->docker_attribute_order }, 31,
    'the parent is unaffected by the child');
};

# ---------------------------------------------------------------------------
# Both spellings, and what the DSL refuses
# ---------------------------------------------------------------------------

subtest 'constructor accepts both spellings' => sub {
  my $a = API::Docker::Type::Port->new(private_port => 80, type => 'tcp');
  my $b = API::Docker::Type::Port->from_data({ PrivatePort => 80, Type => 'tcp' });
  is($json->encode($a->TO_JSON), $json->encode($b->TO_JSON),
    'a Perl name and a wire name reach the same attribute');
  is_deeply($a->unknown_fields, {}, 'and neither is filed as unknown');
  like(
    do { local $@; eval { API::Docker::Type::Port->from_data([]) }; $@ },
    qr/needs a HashRef/, 'from_data refuses anything but a hashref');
};

subtest 'the registry is what the drift checker reads' => sub {
  my $reg = API::Docker::Type::HostConfig->docker_attributes;
  is(API::Docker::Type::describe_type($reg->{port_bindings}{type}),
    'hash<array<object<API::Docker::Type::PortBinding>>>',
    'a PortMap is a hash of arrays of typed objects');
  is(API::Docker::Type::describe_type($reg->{binds}{type}), 'array<str>',
    'and Binds an array of strings');
  is(API::Docker::Type::describe_type($reg->{privileged}{type}), 'bool');
  is(API::Docker::Type::describe_type($reg->{log_config}{type}),
    'object<API::Docker::Type::HostConfig::LogConfig>',
    'an inline schema is a class named after the definition declaring it');
  is($reg->{port_bindings}{required}, 0, 'required is recorded');
  is(API::Docker::Type::Port->docker_attributes->{private_port}{required}, 1,
    'including where the spec sets it');
  is_deeply(API::Docker::Type::Mount->docker_attributes->{type}{enum},
    [qw( bind cluster image npipe tmpfs volume )],
    'and an enumeration, for the POD to state');
};

# ---------------------------------------------------------------------------
# The two entry points have different jobs (karr k85)
# ---------------------------------------------------------------------------

subtest 'from_data reads a response, so a key it does not know stays a key' => sub {
  # A decoded daemon response is a map of WIRE names, and the swagger spells
  # 114 of them with a lowercase first letter -- BuildInfo.id among them. So
  # a lowercase key off an engine is ordinary, not exotic, and reading it as
  # the Perl spelling of a field we happen to know renames the engine's data.
  my $both = API::Docker::Type::ContainerInspectResponse->from_data({
    Id => 'known', id => 'lowercase-new-field' });
  is($both->id, 'known', 'the wire name Id is what fills the id attribute');
  is_deeply($both->unknown_fields, { id => 'lowercase-new-field' },
    'and a key that is only a Perl spelling is a field we have not heard of');
  is_deeply($both->TO_JSON, { Id => 'known', id => 'lowercase-new-field' },
    'both go back out under the name they arrived with');

  my $only = API::Docker::Type::ContainerInspectResponse->from_data({
    id => 'lowercase-new-field' });
  is($only->id, undef, 'an unknown key fills no attribute');
  is_deeply($only->TO_JSON, { id => 'lowercase-new-field' },
    'and is not rewritten to Id on the way out');

  # The same one level down: the coercion that inflates a nested hashref is
  # on the response path too when from_data is what started it.
  my $nested = API::Docker::Type::ContainerInspectResponse->from_data({
    State => { Status => 'running', status => 'newer-engine' } });
  is($nested->state->status, 'running', 'a nested wire name inflates');
  is_deeply($nested->state->unknown_fields, { status => 'newer-engine' },
    'and a nested key we do not know is kept, not folded into the one we do');

  # An entity attribute reaches the object only through the %extra pairs the
  # resource API passes after the hashref -- never out of the response itself.
  # That is how every API::Docker::API::* calls from_data:
  # $class->from_data($data, client => $self->client).
  my $client = bless {}, 'API::Docker';
  my $summary = API::Docker::Type::ContainerSummary->from_data(
    { Id => 'abc' }, client => $client);
  is($summary->client, $client, 'an entity attribute passed as %extra reaches the object');
  is_deeply($summary->unknown_fields, {},
    'and nothing the daemon did not send is filed as unknown');

  # A response key that merely spells an entity attribute is the caller's
  # field to keep, not ours to route into the constructor. This is the whole
  # point of keeping %extra apart from $data: no engine sends `client` today,
  # which is exactly the case the passthrough invariant exists for. On the old
  # code the non-ref case croaked `Can't weaken a nonreference`, and a ref
  # vanished from unknown_fields and TO_JSON both (karr k104).
  my $stray = API::Docker::Type::ContainerSummary->from_data(
    { Id => 'abc', client => 'DAEMON' });
  is($stray->client, undef,
    'a response key named like an entity attribute fills no attribute');
  is_deeply($stray->unknown_fields, { client => 'DAEMON' },
    'it is kept verbatim as an unknown field');
  is_deeply($stray->TO_JSON, { Id => 'abc', client => 'DAEMON' },
    'and comes back out unchanged, croaking no more on a non-reference');

  # Both together: the injected client sets the real attribute, and a
  # same-named response key is still forwarded as unknown -- they coexist, and
  # TO_JSON offers the daemon its own value rather than the client object.
  my $both_c = API::Docker::Type::ContainerSummary->from_data(
    { Id => 'abc', client => 'DAEMON' }, client => $client);
  is($both_c->client, $client, 'the injected client sets the real attribute');
  is_deeply($both_c->unknown_fields, { client => 'DAEMON' },
    'while the response key of that name stays an unknown field beside it');
  is_deeply($both_c->TO_JSON, { Id => 'abc', client => 'DAEMON' },
    'and the client object is never offered to the engine');
};

subtest 'new builds a request, so a Perl name still works' => sub {
  my $hc = API::Docker::Type::HostConfig->new(privileged => 1, Binds => ['/a:/b']);
  is_deeply($hc->TO_JSON, { Privileged => JSON->true, Binds => ['/a:/b'] },
    'either spelling reaches the attribute when the caller is the author');

  # A nested hashref a caller wrote is caller data too, not a response.
  my $nested = API::Docker::Type::HostConfig->new(
    restart_policy => { name => 'always' });
  is_deeply($nested->TO_JSON, { RestartPolicy => { Name => 'always' } },
    'and so is a nested one');
};

subtest 'an ambiguous constructor is refused, not resolved by hash order' => sub {
  # Both keys land on the same attribute and only hash order decided which
  # one won -- measured at 9 zeroes and 11 ones over 20 constructions.
  like(
    do { local $@; eval {
      API::Docker::Type::HostConfig->new(privileged => 0, Privileged => 1) }; $@ },
    qr/\Qgot 'Privileged' and 'privileged' for the same field 'privileged'\E/,
    'two spellings of one field croak instead of picking one');
  like(
    do { local $@; eval {
      API::Docker::Type::HostConfig->new(privileged => 1, Privileged => 1) }; $@ },
    qr/\Qfor the same field 'privileged'\E/,
    'and they croak when the two values agree -- accidentally equal is not '
      . 'unambiguous, and the caller should see the mistake, not the luck');

  ok(API::Docker::Type::HostConfig->new(privileged => 1),
    'one spelling on its own is still fine');
  ok(API::Docker::Type::HostConfig->new(Privileged => 1), 'either one');
};

subtest 'BUILDARGS is idempotent, unknown_fields included' => sub {
  # HostConfig resolves an allOf, so this role is composed into it AND into
  # Resources and the modifier runs twice over the same arguments. The
  # second pass must not refile the first pass's work as unknown.
  my $hc = API::Docker::Type::HostConfig->new(
    unknown_fields => { AlreadyThere => 'kept' },
    privileged     => 1,
    Binds          => ['/a:/b'],
    CpuShares      => 512,
    SomethingNew   => 'x',
  );
  is_deeply($hc->unknown_fields, { AlreadyThere => 'kept', SomethingNew => 'x' },
    'a populated unknown_fields survives the second pass and is added to');
  is($hc->privileged, 1, 'a Perl name resolved on the first pass stays resolved');
  is($hc->cpu_shares, 512, 'and so does an inherited wire name');
  is_deeply($hc->TO_JSON, {
    AlreadyThere => 'kept', SomethingNew => 'x',
    Privileged   => JSON->true, Binds => ['/a:/b'], CpuShares => 512,
  }, 'and all of it goes out together');

  my $round = API::Docker::Type::HostConfig->from_data($hc->TO_JSON);
  is($json->encode($round->TO_JSON), $json->encode($hc->TO_JSON),
    'the response path is idempotent over the same two passes');
};

# ---------------------------------------------------------------------------
# A value that disagrees with the swagger costs its own field, not the
# response it arrived in -- on the response path only (karr k83, option b)
# ---------------------------------------------------------------------------

subtest 'from_data keeps a value it cannot use instead of croaking' => sub {
  # The swagger declares ContainerInspectResponse.State as an object. An
  # engine that answers with the bare status string of the list shape used to
  # take the whole inspect down with an Error::TypeTiny; now it costs that
  # one field. We are not the authority on what an engine answers -- the
  # model is v1.51, and an engine announces whatever version it has (Podman
  # 5.8 says 1.44, Docker 29.7 says 1.55).
  my $c = API::Docker::Type::ContainerInspectResponse->from_data({
    Id => 'x', Name => '/keep', State => 'exited' });

  is($c->id, 'x', 'every other field of the response is still there');
  is($c->name, '/keep', 'including the ones after the one that did not fit');
  is($c->state, undef, 'the field that did not fit is not set');
  is_deeply($c->rejected_fields, { State => 'state' },
    'the wire name is recorded, with the attribute it would have filled');
  is_deeply($c->unknown_fields, { State => 'exited' },
    'and the raw value is kept under that wire name');
  is_deeply($c->TO_JSON, { Id => 'x', Name => '/keep', State => 'exited' },
    'so TO_JSON writes it back byte for byte -- nothing is lost');

  # The precedence question k85 defect 4 asks does not arise out of a
  # response: a value lands in unknown_fields under a KNOWN wire name only
  # when its attribute was left unset, and TO_JSON omits an unset attribute,
  # so the two never meet on this path.
  my $round = API::Docker::Type::ContainerInspectResponse->from_data($c->TO_JSON);
  is($json->encode($round->TO_JSON), $json->encode($c->TO_JSON),
    'a rejected value survives a second pass through the model unchanged');
  is_deeply($round->rejected_fields, { State => 'state' },
    'and is still reported as rejected rather than as merely unknown');

  # Absent and rejected must not be the same observation.
  my $absent = API::Docker::Type::ContainerInspectResponse->from_data({ Id => 'x' });
  is($absent->state, undef, 'an absent field leaves the accessor undef too');
  is_deeply($absent->rejected_fields, {},
    'but nothing is recorded as rejected, which is how the two are told apart');
  ok(!exists $absent->unknown_fields->{State},
    'and nothing is kept under its name');

  # Anything the coercion itself refuses is the same case, not a special one.
  my $bool = API::Docker::Type::Mount->from_data({ Target => '/x', ReadOnly => [1] });
  is($bool->read_only, undef, 'a Bool that can mean neither is not set');
  is_deeply($bool->rejected_fields, { ReadOnly => 'read_only' },
    'it is reported as rejected');
  is_deeply($bool->TO_JSON, { Target => '/x', ReadOnly => [1] },
    'and its value still reaches the daemon as it arrived');

  # One level down, through the coercion that inflates a nested object.
  my $nested = API::Docker::Type::HostConfig->from_data({
    RestartPolicy => { Name => 'always', MaximumRetryCount => 'many' } });
  is($nested->restart_policy->name, 'always', 'the nested object still inflates');
  is($nested->restart_policy->maximum_retry_count, undef,
    'and only the field inside it that did not fit is unset');
  is_deeply($nested->TO_JSON,
    { RestartPolicy => { Name => 'always', MaximumRetryCount => 'many' } },
    'the nested raw value goes back out too');
};

subtest 'new is strict, and stays strict' => sub {
  # The leniency belongs to the path that inflates an engine response. A
  # caller who writes a value the swagger does not allow has made a typo, and
  # a typo in a request is worth dying on.
  like(
    do { local $@; eval {
      API::Docker::Type::ContainerInspectResponse->new(State => 'exited') }; $@ },
    qr/did not pass type constraint|State/,
    'a value that does not fit croaks out of new');
  like(
    do { local $@; eval {
      API::Docker::Type::HostConfig->new(
        restart_policy => { Name => 'always', MaximumRetryCount => 'many' }) }; $@ },
    qr/did not pass type constraint|MaximumRetryCount|maximum_retry_count/,
    'and so does one inside a nested hashref the caller wrote');
  like(
    do { local $@; eval { API::Docker::Type::Mount->new(read_only => [1]) }; $@ },
    qr/Bool wants a scalar/,
    'a Bool that can mean neither still croaks rather than being guessed at');

  my $ok = API::Docker::Type::ContainerInspectResponse->new(Id => 'x');
  is_deeply($ok->rejected_fields, {},
    'an object a caller built never has anything in rejected_fields');

  # The leniency hangs on the entry point, not on the flag that tells a
  # nested coercion which entry point it is under. Were it the flag, a `new`
  # reached from inside a response inflation would go soft with it.
  like(
    do { local $@;
         local $API::Docker::Role::Type::RESPONSE = 1;
         eval { API::Docker::Type::ContainerInspectResponse->new(State => 'exited') };
         $@ },
    qr/did not pass type constraint|State/,
    'new croaks even while a response is being inflated around it');
};

subtest 'the DSL refuses two fields on one wire name' => sub {
  # _docker_wire_index is a map from wire name to Perl name, so a second
  # field claiming a wire name would make the first unreachable on
  # inflation while TO_JSON wrote both to the one key. Nothing in the 201
  # generated classes does this; the generator could emit it tomorrow.
  my $err = do { local $@; eval q{
    package API::Docker::Type::TypeTestDuplicateWire;
    use API::Docker::Type;
    docker cpu_shares => Int, wire => 'CPUShares';
    docker shares     => Int, wire => 'CPUShares';
    1;
  }; $@ };
  like($err, qr/\Qwire name 'CPUShares'\E/,
    'a duplicate wire name is refused where a duplicate Perl name already is');
  like($err, qr/cpu_shares/, 'and the message names the field that has it');

  my $ok = do { local $@; eval q{
    package API::Docker::Type::TypeTestDistinctWire;
    use API::Docker::Type;
    docker cpu_shares => Int, wire => 'CPUShares';
    docker shares     => Int;
    1;
  }; $@ };
  is($ok, '', 'two fields with distinct wire names are still fine');

  my $dup = do { local $@; eval q{
    package API::Docker::Type::TypeTestDuplicatePerl;
    use API::Docker::Type;
    docker shares => Int;
    docker shares => Int, wire => 'Other';
    1;
  }; $@ };
  like($dup, qr/declared twice/, 'and the Perl-name guard is untouched');
};

done_testing;
