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

# status_requires_claim used to walk `statuses` itself, next to status_config
# doing the same walk for no caller at all (ticket #121). It now reads
# status_config's entry, so both are pinned here: the entry each status shape
# resolves to, and the boolean derived from it. The pair matters more than
# either half -- the fold is only safe because a bare status synthesizes an
# entry with no require_claim key, which is exactly the bare-string rule this
# file records above.
subtest 'status_config resolves one status to what the board says about it' => sub {
  my $config = App::karr::Config->from_merged( App::karr::Config->default_config );

  is_deeply $config->status_config('in-progress'),
    { name => 'in-progress', require_claim => 1 },
    'mapping status comes back as configured, require_claim included';
  is_deeply $config->status_config('backlog'), { name => 'backlog' },
    'bare status is synthesized into an entry carrying only its name';
  ok !exists $config->status_config('backlog')->{require_claim},
    '...and no require_claim key, which is what makes it need no claim';
  is $config->status_config('missing'), undef, 'unknown status has no entry';

  my $custom = App::karr::Config->from_merged({
    statuses => [
      'open',
      { name => 'gated',        require_claim => 1 },
      { name => 'ungated' },
      { name => 'explicit-off', require_claim => 0 },
    ],
  });
  is_deeply $custom->status_config('open'), { name => 'open' },
    'bare custom status synthesizes an entry';
  is_deeply $custom->status_config('ungated'), { name => 'ungated' },
    'mapping without require_claim keeps its shape';
  is_deeply $custom->status_config('explicit-off'),
    { name => 'explicit-off', require_claim => 0 },
    'an explicit false is preserved in the entry, not dropped';
  is $custom->status_config('gated')->{require_claim}, 1,
    'the flag status_requires_claim reads is on the entry';
};

subtest 'status_requires_claim is status_config require_claim as a boolean' => sub {
  my $config = App::karr::Config->from_merged({
    statuses => [
      'open',
      { name => 'gated',        require_claim => 1 },
      { name => 'ungated' },
      { name => 'explicit-off', require_claim => 0 },
    ],
  });

  # Re-inlining the lookup, or reintroducing the old "a bare string requires a
  # claim" answer status_config never gave, breaks this loop.
  for my $status (qw( open gated ungated explicit-off backlog missing )) {
    my $entry = $config->status_config($status);
    is $config->status_requires_claim($status),
      ( $entry && $entry->{require_claim} ) ? 1 : 0,
      "status_requires_claim('$status') agrees with its status_config entry";
  }

  my $default = App::karr::Config->from_merged( App::karr::Config->default_config );
  for my $status ( $default->statuses, 'nonexistent' ) {
    my $entry = $default->status_config($status);
    is $default->status_requires_claim($status),
      ( $entry && $entry->{require_claim} ) ? 1 : 0,
      "default board: '$status' agrees with its status_config entry";
  }
};

subtest 'the MockStore double answers status_requires_claim like Config' => sub {
  require MockStore;

  my $ec = App::karr::Config->effective_config({
    statuses => [
      'inbox',
      { name => 'doing',   require_claim => 1 },
      { name => 'waiting' },
      'shipped',
    ],
  });
  my $mock      = MockStore->new( ec => $ec );
  my $canonical = App::karr::Config->from_merged($ec);

  for my $status (qw( inbox doing waiting shipped in-progress unknown )) {
    is $mock->status_requires_claim($status),
       $canonical->status_requires_claim($status),
       "mock: status_requires_claim('$status') matches Config";
  }
  is $mock->status_requires_claim('doing'), 1, 'mock: require_claim status needs a claim';
  is $mock->status_requires_claim('inbox'), 0, 'mock: bare status does not';
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
