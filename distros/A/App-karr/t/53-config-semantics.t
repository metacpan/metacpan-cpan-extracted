use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );

use App::karr::Config;
use App::karr::Git;
use App::karr::BoardStore;

# is_terminal_status, status_requires_claim and _merge_hashes now live once in
# Config; BoardStore keeps thin delegating wrappers (ticket #26). These tests
# lock the canonical semantics and prove the wrappers cannot silently drift.
#
# Deliberate resolution recorded here: a bare-string status does NOT require a
# claim. Only statuses explicitly flagged require_claim => 1 do. This matches
# the behaviour Move.pm has always relied on via BoardStore (and the test
# MockStore double); Config's private copy previously returned the opposite for
# bare strings but had no caller, so folding it in fixes that latent divergence.

subtest 'is_terminal_status recognises done and archived only' => sub {
  ok(  App::karr::Config->is_terminal_status('done'),        'done is terminal' );
  ok(  App::karr::Config->is_terminal_status('archived'),    'archived is terminal' );
  ok( !App::karr::Config->is_terminal_status('backlog'),     'backlog is not terminal' );
  ok( !App::karr::Config->is_terminal_status('in-progress'), 'in-progress is not terminal' );
  ok( !App::karr::Config->is_terminal_status('nonsense'),    'unknown status is not terminal' );
};

subtest 'status_requires_claim: bare strings never require a claim' => sub {
  my $config = App::karr::Config->from_merged( App::karr::Config->default_config );

  is $config->status_requires_claim('backlog'),     0, 'bare backlog does not require claim';
  is $config->status_requires_claim('todo'),        0, 'bare todo does not require claim';
  is $config->status_requires_claim('in-progress'), 1, 'in-progress requires claim';
  is $config->status_requires_claim('review'),      1, 'review requires claim';
  is $config->status_requires_claim('done'),        0, 'bare done does not require claim';
  is $config->status_requires_claim('archived'),    0, 'bare archived does not require claim';
  is $config->status_requires_claim('missing'),     0, 'unknown status does not require claim';
};

subtest 'status_requires_claim honours require_claim flag on custom statuses' => sub {
  my $config = App::karr::Config->from_merged({
    statuses => [
      'open',
      { name => 'gated',        require_claim => 1 },
      { name => 'ungated' },
      { name => 'explicit-off', require_claim => 0 },
    ],
  });

  is $config->status_requires_claim('open'),         0, 'bare custom status does not require claim';
  is $config->status_requires_claim('gated'),        1, 'require_claim => 1 requires claim';
  is $config->status_requires_claim('ungated'),      0, 'hashref without require_claim does not';
  is $config->status_requires_claim('explicit-off'), 0, 'require_claim => 0 does not require claim';
};

subtest 'BoardStore wrappers match canonical Config on the production path' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0
    or plan skip_all => 'git init failed';

  my $git   = App::karr::Git->new( dir => $repo );
  my $store = App::karr::BoardStore->new( git => $git );

  # Absolute values through the interface Move.pm actually calls.
  is $store->status_requires_claim('backlog'),     0, 'store: bare backlog no claim';
  is $store->status_requires_claim('in-progress'), 1, 'store: in-progress needs claim';
  is $store->status_requires_claim('review'),      1, 'store: review needs claim';
  is $store->status_requires_claim('done'),        0, 'store: bare done no claim';
  ok  $store->is_terminal_status('done'),     'store: done is terminal';
  ok !$store->is_terminal_status('backlog'),  'store: backlog is not terminal';

  # The wrappers must equal the canonical Config computed from the same
  # effective config, so they cannot re-diverge.
  my $canonical = App::karr::Config->from_merged( $store->effective_config );
  for my $status (qw( backlog todo in-progress review done archived unknown )) {
    is $store->status_requires_claim($status),
       $canonical->status_requires_claim($status),
       "status_requires_claim('$status') matches Config";
    is !!$store->is_terminal_status($status),
       !!App::karr::Config->is_terminal_status($status),
       "is_terminal_status('$status') matches Config";
  }

  # load_config is the surviving _merge_hashes consumer; it must equal the
  # canonical effective_config merge now that the duplicate merger is gone.
  is_deeply
    $store->load_config,
    App::karr::Config->effective_config( $store->load_config_overrides ),
    'load_config equals Config->effective_config(overrides)';
};

done_testing;
