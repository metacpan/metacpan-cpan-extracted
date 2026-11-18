#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use API::Docker;

# API::Docker::Role::Using -- ->using clones a resource class so that a run of
# calls can carry its own transport bounds (karr k74). What the clone does
# with them is t/timeout_forwarding.t's subject, for every method there is;
# this is the clone itself: what it shares with the original, what it must not
# share, and what it refuses.
#
# Nothing here reaches a daemon: _request is replaced outright, so no socket
# is opened and the paths arrive unprefixed.

package Test::Using::Probe;
use Moo;
extends 'API::Docker';

has calls => (is => 'ro', default => sub { [] });

sub _request {
  my ($self, $method, $path, %opts) = @_;
  push @{ $self->calls }, { method => $method, path => $path, opts => \%opts };
  return [ { Id => 'c1', Names => ['/one'] } ] if $path eq '/containers/json';
  return [] if $path eq '/images/json';
  return {};
}

package main;

my $HOST = 'unix:///nonexistent-api-docker-74.sock';

sub probe { Test::Using::Probe->new(host => $HOST, api_version => '1.41') }

# The two options of the last request the probe was asked for.
sub last_bounds {
  my ($probe) = @_;
  my $call = $probe->calls->[-1] or return 'nothing was requested';
  return { map { exists $call->{opts}{$_} ? ($_ => $call->{opts}{$_}) : () }
    qw( read_timeout connect_timeout ) };
}

# ---------------------------------------------------------------------------
subtest 'the clone is a resource class of the same kind' => sub {
  my $docker = probe();
  my $resource = $docker->containers;
  my $clone    = $resource->using(read_timeout => 5);

  isa_ok $clone, 'API::Docker::API::Containers';
  isnt $clone, $resource, 'and a different object, not the one it came from';

  # The other roles are still composed on the clone -- it is built through the
  # class's own constructor, not assembled by hand.
  ok $clone->can('_normalise_filters'),
    'API::Docker::Role::Filters is composed on it too';

  $clone->list;
  is_deeply last_bounds($docker), { read_timeout => 5 },
    'and a call through it carries what it was cloned with';
};

subtest 'every resource class has one' => sub {
  my $docker = probe();

  for my $accessor (qw( system containers images networks volumes exec
    distribution secrets configs plugins )) {
    my $resource = $docker->$accessor;
    my $clone    = $resource->using(read_timeout => 5);
    is ref $clone, ref $resource, $accessor . '->using returns its own class';
    is_deeply $clone->_request_options, { read_timeout => 5 },
      $accessor . '->using carries the option';
  }
};

# ---------------------------------------------------------------------------
subtest 'the original is not touched, and two clones do not see each other'
  => sub {
  my $docker = probe();
  my $resource = $docker->containers;

  my $tight = $resource->using(read_timeout => 5);
  my $loose = $resource->using(read_timeout => 600, connect_timeout => 2);

  is_deeply $resource->_request_options, {},
    'the resource class ->using was called on carries nothing afterwards';
  is_deeply $tight->_request_options, { read_timeout => 5 },
    'the first clone has only its own';
  is_deeply $loose->_request_options,
    { read_timeout => 600, connect_timeout => 2 },
    'the second clone has only its own';

  isnt $tight->_request_options, $loose->_request_options,
    'and they are not the same HashRef, so neither can edit the other';

  # $docker->containers is a lazy attribute, so the object ->using was called
  # on is the one every later call goes through: a ->using that mutated it
  # would bound the whole client from then on.
  $docker->containers->list;
  is_deeply last_bounds($docker), {},
    'a call through the client itself is still unbounded';
};

# ---------------------------------------------------------------------------
# The resource classes hold the client as a weak_ref, and the clone is built
# through the same constructor, so it holds it on the same terms. Both
# directions are asserted, because a clone that took a strong reference would
# leak the client and a clone that copied the client instead of sharing it
# would hand every entity a client that is already gone.
subtest 'the clone shares the client and does not keep it alive' => sub {
  my $docker = probe();
  my $clone  = $docker->containers->using(read_timeout => 5);

  is $clone->client, $docker,
    'the identical client object, not a copy of it';

  my $entities = $clone->list;
  is $entities->[0]->client, $docker,
    'and an entity built by a call through the clone carries that same client';

  my $orphan;
  {
    my $short_lived = probe();
    $orphan = $short_lived->containers->using(read_timeout => 5);
    isa_ok $orphan->client, 'API::Docker', 'inside the scope the client';
  }

  is $orphan->client, undef,
    'once the caller lets the client go, the clone does not hold it up';

  # And says so rather than quietly doing nothing -- the failure a caller sees
  # when they keep the clone but not the client.
  eval { $orphan->list };
  like $@, qr/undefined value/,
    'a call through a clone whose client is gone dies on the undefined client';
};

# ---------------------------------------------------------------------------
subtest 'chaining merges, and a repeated key takes the later value' => sub {
  my $docker = probe();

  my $both = $docker->images->using(connect_timeout => 2)
                    ->using(read_timeout => 60);
  is_deeply $both->_request_options,
    { connect_timeout => 2, read_timeout => 60 },
    'the second ->using keeps what the first carried';

  my $off = $both->using(read_timeout => 0);
  is_deeply $off->_request_options,
    { connect_timeout => 2, read_timeout => 0 },
    'and replaces only the key it names -- an explicit 0 included';

  is_deeply $both->_request_options,
    { connect_timeout => 2, read_timeout => 60 },
    'without changing the clone it was called on';

  $off->list;
  is_deeply last_bounds($docker), { connect_timeout => 2, read_timeout => 0 },
    'and the merged pair is what reaches the request';
};

# ---------------------------------------------------------------------------
# A ->using that quietly carried nothing would leave the caller believing a
# bound is in force that is not, which is the failure the bounds exist to
# prevent. So all three refusals are loud.
subtest 'what ->using refuses' => sub {
  my $docker = probe();
  my $resource = $docker->containers;

  eval { $resource->using(read_timout => 5) };
  like $@, qr/does not carry 'read_timout'/,
    'an unknown option croaks, naming it';
  like $@, qr/connect_timeout and read_timeout/,
    'and says what it does carry';

  eval { $resource->using() };
  like $@, qr/given nothing to carry/, 'an empty call croaks';

  eval { $resource->using('read_timeout') };
  like $@, qr/odd number of arguments/,
    'an odd number of arguments croaks before the pairs are read';

  # An option of the transport that is not one of the two: a per-request thing
  # -- a streaming callback, the response out-parameter -- belongs to one call
  # and cannot be carried by a clone.
  eval { $resource->using(on_event => sub { }) };
  like $@, qr/does not carry 'on_event'/,
    'a per-request option of _request is refused as well';

  eval { $resource->using(read_timeout => 5, bogus => 1) };
  like $@, qr/does not carry 'bogus'/,
    'and one bad key among good ones is enough';
};

done_testing;
