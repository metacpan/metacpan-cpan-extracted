#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use API::Docker;

# Every public resource method that reaches the daemon carries the bounds its
# resource class was cloned with (karr k74). The two options used to be
# arguments of each method (karr k70, karr k72); they are now carried by the
# clone API::Docker::Role::Using/using returns, and a method either splices
# that clone's options into the list it hands the transport or drops them on
# the floor.
#
# Dropping them is silent -- %{ $self->_request_options } is an interpolation
# nothing forces a method to write -- so `networks->using(read_timeout => 5)
# ->list` would return normally having ignored the bound entirely. That is
# what this asserts, at the seam the value has to cross, for every method
# there is.
#
# The pre-flight requests are in the table too -- the running check attach
# makes, the privileges fetch install and upgrade make under
# accept_privileges => 1 -- named by the endpoint they issue rather than by
# the method, because a caller who set a bound and then hangs in a request
# they never wrote has been told something untrue. They need no forwarding of
# their own here: they run on the same resource class, which is the whole
# point of putting the bounds there.
#
# Nothing here reaches a daemon and nothing here opens a socket: _request is
# replaced outright, which takes API::Docker's version-negotiation `around`
# with it, so the paths arrive unprefixed. The negotiation is asserted
# separately at the bottom, where that `around` has to stay in place.

package Test::TimeoutForward::Probe;
use Moo;
extends 'API::Docker';

has calls => (is => 'ro', default => sub { [] });

sub _request {
  my ($self, $method, $path, %opts) = @_;
  push @{ $self->calls }, { method => $method, path => $path, opts => \%opts };

  # Shaped only so the method under test can finish. What it does with the
  # answer is asserted elsewhere; the option list it built is what matters
  # here. The container inspect is attach()'s running-check pre-flight.
  # /version must carry a well-formed ApiVersion, or negotiate_version croaks
  # before the recorded call can be asserted.
  return { ApiVersion => '1.41' } if $path eq '/version';
  return { State => { Running => 1 } } if $path =~ m{^/containers/[^/]+/json$};
  return { Volumes => [] }             if $path eq '/volumes';
  return []
    if $path =~ m{^/(?:containers/json|images/json|networks|secrets|configs|plugins)$};
  return [] if $path =~ m{/stats$};
  # The inspects, which wrap what comes back in an entity object.
  return {} if $path =~ m{/json$};
  return {} if $path =~ m{^/(?:networks|volumes|secrets|configs)/[^/]+$};
  return '';
}

# Records what _build__socket was handed rather than connecting, the way
# t/connect_timeout.t does -- but reached through a resource method, which is
# what the bound exists for.
package Test::TimeoutForward::ConnectProbe;
use Moo;
extends 'API::Docker';

has seen => (is => 'ro', required => 1);

sub _build__socket {
  my ($self) = @_;
  my $pending = $self->_pending_connect;
  push @{ $self->seen }, $pending ? $pending->{timeout} : 'no pending';
  die "no socket here\n";
}

# _request is left alone here so that API::Docker's `around` still runs and
# still triggers the negotiation; only the negotiation itself is intercepted.
package Test::TimeoutForward::NegotiateProbe;
use Moo;
extends 'API::Docker';

has negotiations => (is => 'ro', default => sub { [] });

sub negotiate_version {
  my ($self, %opts) = @_;
  push @{ $self->negotiations }, \%opts;
  # What the real one does on success, so the request that triggered it can
  # go on and only one negotiation is recorded per client.
  $self->_set_api_version('1.41');
  $self->_version_negotiated(1);
  return;
}

sub _build__socket { die "no socket here\n" }

package main;

# id, the endpoint whose option list carries the answer, the resource class
# accessor ->using is called on, and the call made through it. The endpoint is
# named rather than taken as "the last call", because several of these reach
# the daemon twice and only one of the two is the request being asserted.
my @cases = (
  # -- containers ----------------------------------------------------------
  [ 'containers->list', 'GET /containers/json',
    'containers' => sub { $_[0]->list } ],
  [ 'containers->inspect', 'GET /containers/c1/json',
    'containers' => sub { $_[0]->inspect('c1') } ],
  [ 'containers->start', 'POST /containers/c1/start',
    'containers' => sub { $_[0]->start('c1') } ],
  [ 'containers->stop', 'POST /containers/c1/stop',
    'containers' => sub { $_[0]->stop('c1') } ],
  [ 'containers->restart', 'POST /containers/c1/restart',
    'containers' => sub { $_[0]->restart('c1') } ],
  [ 'containers->kill', 'POST /containers/c1/kill',
    'containers' => sub { $_[0]->kill('c1') } ],
  [ 'containers->remove', 'DELETE /containers/c1',
    'containers' => sub { $_[0]->remove('c1') } ],
  [ 'containers->logs', 'GET /containers/c1/logs',
    'containers' => sub { $_[0]->logs('c1') } ],
  [ 'containers->attach', 'POST /containers/c1/attach',
    'containers' => sub { $_[0]->attach('c1') } ],
  [ 'containers->attach pre-flight', 'GET /containers/c1/json',
    'containers' => sub { $_[0]->attach('c1') } ],
  [ 'containers->top', 'GET /containers/c1/top',
    'containers' => sub { $_[0]->top('c1') } ],
  [ 'containers->stats', 'GET /containers/c1/stats',
    'containers' => sub { $_[0]->stats('c1') } ],
  [ 'containers->changes', 'GET /containers/c1/changes',
    'containers' => sub { $_[0]->changes('c1') } ],
  [ 'containers->export', 'GET /containers/c1/export',
    'containers' => sub { $_[0]->export('c1') } ],
  [ 'containers->resize', 'POST /containers/c1/resize',
    'containers' => sub { $_[0]->resize('c1') } ],
  [ 'containers->wait', 'POST /containers/c1/wait',
    'containers' => sub { $_[0]->wait('c1') } ],
  [ 'containers->pause', 'POST /containers/c1/pause',
    'containers' => sub { $_[0]->pause('c1') } ],
  [ 'containers->unpause', 'POST /containers/c1/unpause',
    'containers' => sub { $_[0]->unpause('c1') } ],
  [ 'containers->rename', 'POST /containers/c1/rename',
    'containers' => sub { $_[0]->rename('c1', 'c2') } ],
  [ 'containers->get_archive', 'GET /containers/c1/archive',
    'containers' => sub { $_[0]->get_archive('c1', path => '/etc') } ],
  [ 'containers->put_archive', 'PUT /containers/c1/archive',
    'containers' => sub { $_[0]->put_archive('c1', 'tar', path => '/etc') } ],
  [ 'containers->stat_archive', 'HEAD /containers/c1/archive',
    'containers' => sub { $_[0]->stat_archive('c1', path => '/etc') } ],
  [ 'containers->prune', 'POST /containers/prune',
    'containers' => sub { $_[0]->prune } ],

  # -- images --------------------------------------------------------------
  [ 'images->list', 'GET /images/json',
    'images' => sub { $_[0]->list } ],
  [ 'images->build', 'POST /build',
    'images' => sub { $_[0]->build(context => 'tar') } ],
  [ 'images->pull', 'POST /images/create',
    'images' => sub { $_[0]->pull(fromImage => 'alpine') } ],
  [ 'images->inspect', 'GET /images/alpine/json',
    'images' => sub { $_[0]->inspect('alpine') } ],
  [ 'images->history', 'GET /images/alpine/history',
    'images' => sub { $_[0]->history('alpine') } ],
  [ 'images->push', 'POST /images/alpine/push',
    'images' => sub { $_[0]->push('alpine') } ],
  [ 'images->tag', 'POST /images/alpine/tag',
    'images' => sub { $_[0]->tag('alpine', repo => 'r') } ],
  [ 'images->remove', 'DELETE /images/alpine',
    'images' => sub { $_[0]->remove('alpine') } ],
  [ 'images->search', 'GET /images/search',
    'images' => sub { $_[0]->search('alpine') } ],
  [ 'images->prune', 'POST /images/prune',
    'images' => sub { $_[0]->prune } ],
  [ 'images->get', 'GET /images/alpine/get',
    'images' => sub { $_[0]->get('alpine') } ],
  [ 'images->get_all', 'GET /images/get',
    'images' => sub { $_[0]->get_all(['alpine']) } ],
  [ 'images->load', 'POST /images/load',
    'images' => sub { $_[0]->load('tar') } ],
  [ 'images->commit', 'POST /commit',
    'images' => sub { $_[0]->commit(container => 'c1') } ],
  [ 'images->build_prune', 'POST /build/prune',
    'images' => sub { $_[0]->build_prune } ],

  # -- networks ------------------------------------------------------------
  [ 'networks->list', 'GET /networks',
    'networks' => sub { $_[0]->list } ],
  [ 'networks->inspect', 'GET /networks/n1',
    'networks' => sub { $_[0]->inspect('n1') } ],
  [ 'networks->remove', 'DELETE /networks/n1',
    'networks' => sub { $_[0]->remove('n1') } ],
  [ 'networks->prune', 'POST /networks/prune',
    'networks' => sub { $_[0]->prune } ],

  # -- volumes -------------------------------------------------------------
  [ 'volumes->list', 'GET /volumes',
    'volumes' => sub { $_[0]->list } ],
  [ 'volumes->inspect', 'GET /volumes/v1',
    'volumes' => sub { $_[0]->inspect('v1') } ],
  [ 'volumes->remove', 'DELETE /volumes/v1',
    'volumes' => sub { $_[0]->remove('v1') } ],
  [ 'volumes->prune', 'POST /volumes/prune',
    'volumes' => sub { $_[0]->prune } ],

  # -- secrets -------------------------------------------------------------
  [ 'secrets->list', 'GET /secrets',
    'secrets' => sub { $_[0]->list } ],
  [ 'secrets->inspect', 'GET /secrets/s1',
    'secrets' => sub { $_[0]->inspect('s1') } ],
  [ 'secrets->remove', 'DELETE /secrets/s1',
    'secrets' => sub { $_[0]->remove('s1') } ],

  # -- configs -------------------------------------------------------------
  [ 'configs->list', 'GET /configs',
    'configs' => sub { $_[0]->list } ],
  [ 'configs->inspect', 'GET /configs/cf1',
    'configs' => sub { $_[0]->inspect('cf1') } ],
  [ 'configs->remove', 'DELETE /configs/cf1',
    'configs' => sub { $_[0]->remove('cf1') } ],

  # -- exec ----------------------------------------------------------------
  [ 'exec->start', 'POST /exec/e1/start',
    'exec' => sub { $_[0]->start('e1') } ],
  [ 'exec->resize', 'POST /exec/e1/resize',
    'exec' => sub { $_[0]->resize('e1', h => 40, w => 120) } ],
  [ 'exec->inspect', 'GET /exec/e1/json',
    'exec' => sub { $_[0]->inspect('e1') } ],

  # -- system --------------------------------------------------------------
  [ 'system->info', 'GET /info',
    'system' => sub { $_[0]->info } ],
  [ 'system->version', 'GET /version',
    'system' => sub { $_[0]->version } ],
  [ 'system->ping', 'GET /_ping',
    'system' => sub { $_[0]->ping } ],
  [ 'system->events', 'GET /events',
    'system' => sub { $_[0]->events } ],
  [ 'system->df', 'GET /system/df',
    'system' => sub { $_[0]->df } ],
  [ 'system->auth', 'POST /auth',
    'system' => sub { $_[0]->auth(username => 'u', password => 'p') } ],

  # -- plugins -------------------------------------------------------------
  [ 'plugins->list', 'GET /plugins',
    'plugins' => sub { $_[0]->list } ],
  [ 'plugins->privileges', 'GET /plugins/privileges',
    'plugins' => sub { $_[0]->privileges('p') } ],
  [ 'plugins->install', 'POST /plugins/pull',
    'plugins' => sub { $_[0]->install('p', privileges => []) } ],
  [ 'plugins->install privileges pre-flight', 'GET /plugins/privileges',
    'plugins' => sub { $_[0]->install('p', accept_privileges => 1) } ],
  [ 'plugins->inspect', 'GET /plugins/p/json',
    'plugins' => sub { $_[0]->inspect('p') } ],
  [ 'plugins->remove', 'DELETE /plugins/p',
    'plugins' => sub { $_[0]->remove('p') } ],
  [ 'plugins->enable', 'POST /plugins/p/enable',
    'plugins' => sub { $_[0]->enable('p') } ],
  [ 'plugins->disable', 'POST /plugins/p/disable',
    'plugins' => sub { $_[0]->disable('p') } ],
  [ 'plugins->upgrade', 'POST /plugins/p/upgrade',
    'plugins' => sub { $_[0]->upgrade('p', privileges => []) } ],
  [ 'plugins->upgrade privileges pre-flight', 'GET /plugins/privileges',
    'plugins' => sub { $_[0]->upgrade('p', accept_privileges => 1) } ],
  [ 'plugins->push', 'POST /plugins/p/push',
    'plugins' => sub { $_[0]->push('p') } ],
  [ 'plugins->configure', 'POST /plugins/p/set',
    'plugins' => sub { $_[0]->configure('p', ['A=1']) } ],

  # -- distribution --------------------------------------------------------
  [ 'distribution->inspect', 'GET /distribution/alpine/json',
    'distribution' => sub { $_[0]->inspect('alpine') } ],
  [ 'distribution->exists', 'GET /distribution/alpine/json',
    'distribution' => sub { $_[0]->exists('alpine') } ],
);

# The option list the named endpoint was requested with, or a string saying
# why there is none -- which is_deeply then reports instead of an empty hash.
# @using is what the resource class is cloned with; empty means it is used as
# it comes off the client.
sub opts_for {
  my ($case, @using) = @_;
  my (undef, $want, $accessor, $code) = @$case;

  my $probe = Test::TimeoutForward::Probe->new(
    host => 'unix:///nonexistent-api-docker-74.sock', api_version => '1.41');

  my $resource = $probe->$accessor;
  $resource = $resource->using(@using) if @using;

  eval { $code->($resource); 1 }
    or return 'the call died before requesting anything: ' . $@;

  my @seen;
  for my $call (@{ $probe->calls }) {
    my $endpoint = $call->{method} . ' ' . $call->{path};
    push @seen, $endpoint;
    return $call->{opts} if $endpoint eq $want;
  }
  return "never requested $want (requested: " . join(', ', @seen) . ')';
}

# What of the two the request was actually given, in a shape is_deeply can
# report: the string opts_for returns when the endpoint was never reached is
# passed through rather than turned into an empty hash.
sub bounds_of {
  my ($opts) = @_;
  return $opts unless ref $opts eq 'HASH';
  return { map { exists $opts->{$_} ? ($_ => $opts->{$_}) : () }
    qw( read_timeout connect_timeout ) };
}

# ---------------------------------------------------------------------------
subtest 'both bounds reach the request the method makes' => sub {
  for my $case (@cases) {
    is_deeply bounds_of(opts_for($case, read_timeout => 3, connect_timeout => 7)),
      { read_timeout => 3, connect_timeout => 7 },
      $case->[0] . ' carries both';
  }
};

# The subtlety `exists` buys, and the one a `? :` on truth would lose: 0 is
# "wait as long as it takes", which is how a client-wide default is turned off
# for a run of calls. Carried on truth it would vanish here and the client
# attribute would win -- the opposite of what the caller asked for.
subtest 'an explicit 0 is carried, not read as "no opinion"' => sub {
  for my $case (@cases) {
    is_deeply bounds_of(opts_for($case, read_timeout => 0, connect_timeout => 0)),
      { read_timeout => 0, connect_timeout => 0 },
      $case->[0] . ' carries an explicit 0 for both';
  }
};

# The other half: a resource class nobody cloned invents neither key, so a
# client carrying an attribute is not overridden with undef by every method
# that could have been bounded.
subtest 'neither is invented on a resource class nobody bounded' => sub {
  for my $case (@cases) {
    my $opts = opts_for($case);
    is_deeply
      ref $opts eq 'HASH'
        ? [ sort grep { exists $opts->{$_} } qw( read_timeout connect_timeout ) ]
        : $opts,
      [],
      $case->[0] . ' passes neither key on';
  }
};

# ---------------------------------------------------------------------------
# Version negotiation is the pre-flight nobody writes: it happens once, before
# the first request of a client with no api_version, and a bound that does not
# reach it leaves that first request unbounded in the one place the caller
# cannot see (karr k72). Two halves, because the `around` and the method are
# separately capable of dropping it.
subtest 'the negotiation inherits the triggering request bounds' => sub {
  for my $args ([ read_timeout => 3, connect_timeout => 7 ],
                [ read_timeout => 0, connect_timeout => 0 ],
                []) {
    my $probe = Test::TimeoutForward::NegotiateProbe->new(
      host => 'unix:///nonexistent-api-docker-74.sock');

    my $containers = $probe->containers;
    $containers = $containers->using(@$args) if @$args;
    eval { $containers->list };

    is_deeply $probe->negotiations, [ { @$args } ],
      'containers->using(' . join(', ', @$args) . ')->list negotiates with the same';
  }
};

# negotiate_version is the one method that still takes the two options
# directly: it is a client method, not a resource one, so ->using cannot reach
# it and a caller bounding the negotiation on its own has nowhere else to say
# so.
subtest 'negotiate_version puts them on the /version request' => sub {
  for my $args ([ read_timeout => 3, connect_timeout => 7 ],
                [ read_timeout => 0, connect_timeout => 0 ],
                []) {
    my $probe = Test::TimeoutForward::Probe->new(
      host => 'unix:///nonexistent-api-docker-74.sock');

    $probe->negotiate_version(@$args);

    my ($call) = grep { $_->{path} eq '/version' } @{ $probe->calls };
    is_deeply
      $call ? bounds_of($call->{opts}) : 'never requested /version',
      { @$args },
      'negotiate_version(' . join(', ', @$args) . ') forwards what it was given';
  }
};

# ---------------------------------------------------------------------------
# The carrying above is only worth anything if the transport reads the option,
# so the other end of the wire is asserted too -- that a value ->using put on
# a resource class reaches the socket constructor. t/connect_timeout.t proves
# what the socket then does with it.
subtest 'the transport picks the carried value up' => sub {
  my @seen;

  my $probe = Test::TimeoutForward::ConnectProbe->new(
    host        => 'unix:///nonexistent-api-docker-74.sock',
    api_version => '1.41',
    seen        => \@seen,
  );

  eval { $probe->images->using(connect_timeout => 7)->pull(fromImage => 'alpine') };
  eval { $probe->system->using(connect_timeout => 2)->events };
  eval { $probe->containers->using(connect_timeout => 0)->logs('c1') };
  eval { $probe->images->get('alpine') };
  eval { $probe->networks->using(connect_timeout => 4)->list };
  eval { $probe->volumes->using(connect_timeout => 6)->inspect('v1') };

  is_deeply \@seen, [7, 2, undef, undef, 4, 6],
    'the option resolved per request, an explicit 0 turning the bound off, '
    . 'and nothing armed on a resource class that was never cloned';
};

done_testing;
