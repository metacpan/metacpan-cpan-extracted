use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Load );

use App::karr::Config;
use App::karr::Git;
use App::karr::BoardStore;

# Ticket #32: board-level disable flag for karr-foundation, stored as
# foundation.enabled (+ foundation.reason) in refs/karr/config. These tests
# cover the Config-layer primitives (foundation_enabled/foundation_reason/
# parse_bool) and the BoardStore round trip that ultimately backs `karr
# disable`/`karr enable`. All Git state lives in throwaway tempdir repos --
# never the developer's real board.

# ---------------------------------------------------------------------------
# Config: default_config carries the enabled-by-default switch
# ---------------------------------------------------------------------------

subtest 'default_config: foundation.enabled defaults to 1' => sub {
  my $d = App::karr::Config->default_config;
  is( ref $d->{foundation}, 'HASH', 'foundation key is a hashref' );
  is( $d->{foundation}{enabled}, 1, 'enabled defaults to 1' );
};

# ---------------------------------------------------------------------------
# Config: foundation_enabled
# ---------------------------------------------------------------------------

subtest 'foundation_enabled: default (code default_config)' => sub {
  my $config = App::karr::Config->from_merged( App::karr::Config->default_config );
  is( $config->foundation_enabled, 1, 'a board that never touched the flag is enabled' );
};

subtest 'foundation_enabled: missing foundation key entirely -> enabled' => sub {
  my $config = App::karr::Config->from_merged( {} );
  is( $config->foundation_enabled, 1, 'no foundation key at all still reads as enabled' );
};

subtest 'foundation_enabled: explicit 0 and 1' => sub {
  my $off = App::karr::Config->from_merged( { foundation => { enabled => 0 } } );
  is( $off->foundation_enabled, 0, 'explicit 0 is disabled' );

  my $on = App::karr::Config->from_merged( { foundation => { enabled => 1 } } );
  is( $on->foundation_enabled, 1, 'explicit 1 is enabled' );
};

# ---------------------------------------------------------------------------
# Config: foundation_reason
# ---------------------------------------------------------------------------

subtest 'foundation_reason' => sub {
  my $none = App::karr::Config->from_merged( App::karr::Config->default_config );
  is( $none->foundation_reason, undef, 'no reason on a board that never disabled' );

  my $with = App::karr::Config->from_merged(
    { foundation => { enabled => 0, reason => 'abandoned driver' } } );
  is( $with->foundation_reason, 'abandoned driver', 'reason text returned verbatim' );

  my $empty = App::karr::Config->from_merged(
    { foundation => { enabled => 0, reason => '' } } );
  is( $empty->foundation_reason, undef, 'an empty-string reason reads back as undef' );
};

# ---------------------------------------------------------------------------
# Config: parse_bool
# ---------------------------------------------------------------------------

subtest 'parse_bool: accepted true/false spellings' => sub {
  for my $true (qw( 1 true TRUE True yes YES on ON )) {
    is( App::karr::Config->parse_bool($true), 1, "'$true' -> 1" );
  }
  for my $false (qw( 0 false FALSE False no NO off OFF )) {
    is( App::karr::Config->parse_bool($false), 0, "'$false' -> 0" );
  }
};

subtest "parse_bool: the footgun case -- 'false' must not be Perl-truthy" => sub {
  my $v = App::karr::Config->parse_bool('false');
  ok( !$v, "parse_bool('false') is falsy in Perl too" );
  is( $v, 0, "parse_bool('false') is the number 0, not just falsy" );
};

subtest 'parse_bool: whitespace is trimmed' => sub {
  is( App::karr::Config->parse_bool('  true  '), 1, 'padded true still parses' );
};

subtest 'parse_bool: garbage dies' => sub {
  for my $bad ( 'maybe', 'yes please', 'nope', '2', '', 'truthy' ) {
    my $lbl = length($bad) ? $bad : '(empty string)';
    eval { App::karr::Config->parse_bool($bad) };
    like( $@, qr/Invalid boolean/, "'$lbl' dies with Invalid boolean" );
  }
};

subtest 'parse_bool: undef dies' => sub {
  eval { App::karr::Config->parse_bool(undef) };
  like( $@, qr/Missing boolean value/, 'undef dies with a distinct message' );
};

# ---------------------------------------------------------------------------
# BoardStore round trip against a real (temporary) git repo
# ---------------------------------------------------------------------------

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
  return $repo;
}

# Writes refs/karr/config the way `karr init` does: effective_config()
# (defaults + a sparse override) run back through save_config()'s diff, so
# the raw ref only ever carries what actually differs from the code default.
sub _init_board {
  my ($store) = @_;
  my $effective = App::karr::Config->effective_config( { version => 1 } );
  $store->save_config($effective);
  return;
}

sub _raw_config_ref {
  my ($git) = @_;
  my $content = $git->read_ref('refs/karr/config');
  return {} unless $content;
  return Load($content);
}

subtest 'freshly initialized board: enabled, and no foundation key in the raw ref' => sub {
  my $repo  = _init_repo();
  my $git   = App::karr::Git->new( dir => $repo );
  my $store = App::karr::BoardStore->new( git => $git );
  _init_board($store);

  ok( $store->foundation_enabled, 'fresh board is enabled' );
  is( $store->foundation_reason, undef, 'fresh board has no reason' );

  my $raw = _raw_config_ref($git);
  ok( !exists $raw->{foundation},
    'the raw refs/karr/config content carries no foundation key at all -- '
    . 'the default is implicit, not written out' );
};

subtest 'set_foundation_enabled(0, reason): disables and persists the reason' => sub {
  my $repo  = _init_repo();
  my $git   = App::karr::Git->new( dir => $repo );
  my $store = App::karr::BoardStore->new( git => $git );
  _init_board($store);

  $store->set_foundation_enabled( 0, 'abandoned driver' );

  is( $store->foundation_enabled, 0, 'store reports disabled' );
  is( $store->foundation_reason, 'abandoned driver', 'store reports the reason' );

  my $raw = _raw_config_ref($git);
  is_deeply(
    $raw->{foundation},
    { enabled => 0, reason => 'abandoned driver' },
    'raw ref content stores enabled=>0 and the reason'
  );
};

subtest 're-enabling drops the reason AND removes the whole foundation key from the sparse overrides' => sub {
  my $repo  = _init_repo();
  my $git   = App::karr::Git->new( dir => $repo );
  my $store = App::karr::BoardStore->new( git => $git );
  _init_board($store);

  $store->set_foundation_enabled( 0, 'abandoned driver' );
  my $raw_disabled = _raw_config_ref($git);
  ok( exists $raw_disabled->{foundation}, 'sanity: foundation key present while disabled' );

  $store->set_foundation_enabled(1);

  is( $store->foundation_enabled, 1, 'store reports enabled again' );
  is( $store->foundation_reason, undef, 'store reports no reason after re-enable' );

  # The interesting assertion: because enabled=>1 (no reason) now matches the
  # code default_config exactly, save_config's defaults-diff must drop the
  # *entire* foundation key back out of the persisted overrides -- not just
  # reset enabled to 1 while leaving an empty {} behind.
  my $raw = _raw_config_ref($git);
  ok( !exists $raw->{foundation},
    'foundation key is gone entirely from the raw ref content after re-enable' );
};

subtest 'disable without a reason (undef) stores no reason key' => sub {
  my $repo  = _init_repo();
  my $git   = App::karr::Git->new( dir => $repo );
  my $store = App::karr::BoardStore->new( git => $git );
  _init_board($store);

  $store->set_foundation_enabled( 0, undef );

  is( $store->foundation_enabled, 0, 'disabled' );
  is( $store->foundation_reason, undef, 'no reason' );

  my $raw = _raw_config_ref($git);
  is_deeply( $raw->{foundation}, { enabled => 0 }, 'raw ref carries only enabled=>0' );
};

done_testing;
