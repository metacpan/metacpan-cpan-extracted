use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

BEGIN {
  eval { require Moo; 1 }
    or plan skip_all => 'Moo not installed';
}

use DBIO::Test::MooSchema;
use DBIO::DeploymentHandler;

my $schema;
lives_ok {
  # the shared schema declares no driver; this use declares the fake one
  $schema = DBIO::Test::MooSchema->clone;
  $schema->storage_type('+DBIO::Test::Storage');
  $schema = $schema->connect('DBIO::Test::Storage', '');
} 'connect to DBIO::Test::Storage works';

# --- Basic API surface ----------------------------------------------------

my $dh;
lives_ok {
  $dh = DBIO::DeploymentHandler->new({ schema => $schema });
} 'DBIO::DeploymentHandler->new works';

ok($dh->can($_), "$_ method exists") for qw(
  install upgrade downgrade
  prepare_install prepare_deploy prepare_upgrade
  deploy backup
  database_version version_storage_is_installed
  add_database_version delete_database_version
  next_version_set previous_version_set
  schema to_version version_source upgrade_hooks
);

# Methods that no longer exist on the native deploy method
ok(!$dh->can('upgrade_single_step'),   'upgrade_single_step removed');
ok(!$dh->can('downgrade_single_step'), 'downgrade_single_step removed');
ok(!$dh->can('prepare_downgrade'),     'prepare_downgrade removed');

ok($dh->deploy_method,    'deploy_method sub-object exists');
ok($dh->version_handler,  'version_handler sub-object exists');
ok($dh->version_storage,  'version_storage sub-object exists');

is_deeply($dh->upgrade_hooks, {}, 'upgrade_hooks defaults to empty hashref');

# database_version coerces into initial_version
my $dh2 = DBIO::DeploymentHandler->new({
  schema           => $schema,
  database_version => 5,
});
is($dh2->initial_version, 5, 'database_version coerces to initial_version');

# karr k214: the starting version reaches the version handler. Before, only the
# database_version alias was forwarded; an explicit initial_version argument was
# dropped, so the Monotonic cursor started from undef and next_version_set
# walked from 0 with numeric warnings instead of from the given version.
{
  my $dh3 = DBIO::DeploymentHandler->new({
    schema          => $schema,
    initial_version => 2,
    to_version      => 4,
  });
  is($dh3->initial_version, 2, 'initial_version argument is kept on the handler');
  is($dh3->version_handler->initial_version, 2,
    'initial_version argument reaches the version handler');
  is_deeply($dh3->next_version_set, [2, 3],
    'the version cursor starts from the given initial_version');

  my $dh4 = DBIO::DeploymentHandler->new({
    schema           => $schema,
    database_version => 3,
    to_version       => 4,
  });
  is($dh4->version_handler->initial_version, 3,
    'the database_version alias reaches the version handler too');
  is_deeply($dh4->next_version_set, [3, 4], 'and seeds the cursor');
}

# karr k214: Monotonic's cursor helpers _inc_version/_dec_version called the
# cursor value as a coderef and could never have run; next/previous_version_set
# move the cursor themselves. They are gone.
ok(!DBIO::DeploymentHandler::VersionHandler::Monotonic->can($_), "Monotonic $_ removed")
  for qw(_inc_version _dec_version);

# karr k214: Dad's generic step loops are a template for subclasses that supply
# upgrade_single_step / downgrade_single_step. DBIO::DeploymentHandler replaces
# both loops and no shipped deploy method supplies the steps, so a Dad subclass
# that does not either used to die "Can't locate object method" from inside its
# transaction. Now it refuses up front with a typed exception naming the hook,
# while a subclass that does supply the steps still gets the loop.
{
  package K214::Dad;
  use base 'DBIO::DeploymentHandler::Dad';
  sub txn_do { $_[1]->() }
  sub next_version_set     { my $s = shift; shift @{ $s->{up}   ||= [] } }
  sub previous_version_set { my $s = shift; shift @{ $s->{down} ||= [] } }
  sub add_database_version    { push @{ $_[0]{added}   }, $_[1]{version} }
  sub delete_database_version { push @{ $_[0]{deleted} }, $_[1]{version} }

  package K214::DadWithSteps;
  our @ISA = ('K214::Dad');
  sub upgrade_single_step   { push @{ $_[0]{steps} }, "up:@{ $_[1]{version_set} }"; [ 'ddl', 'sql' ] }
  sub downgrade_single_step { push @{ $_[0]{steps} }, "down:@{ $_[1]{version_set} }"; [] }
}

{
  my $bare = K214::Dad->new(up => [ [1, 2] ], down => [ [2, 1] ]);
  throws_ok { local $SIG{__WARN__} = sub {}; $bare->upgrade }
    qr/upgrade_single_step/, 'Dad::upgrade without a step method names the missing hook';
  isa_ok($@, 'DBIO::Exception', 'the upgrade refusal');
  ok(!$bare->{added}, 'and records no version');
  throws_ok { local $SIG{__WARN__} = sub {}; $bare->downgrade }
    qr/downgrade_single_step/, 'Dad::downgrade without a step method names the missing hook';

  my $stepped = K214::DadWithSteps->new(up => [ [1, 2], [2, 3] ], down => [ [3, 2] ]);
  { local $SIG{__WARN__} = sub {}; $stepped->upgrade; $stepped->downgrade }
  is_deeply($stepped->{steps}, [ 'up:1 2', 'up:2 3', 'down:3 2' ],
    'a Dad subclass supplying the steps still runs the template loops');
  is_deeply($stepped->{added},   [ 2, 3 ], 'upgrade records each reached version');
  is_deeply($stepped->{deleted}, [ 3 ],    'downgrade deletes the left version');
}

# --- Native deploy method shape ------------------------------------------

my $dm = $dh->deploy_method;
ok($dm->can('deploy'),                       'deploy on deploy_method');
ok($dm->can('upgrade'),                      'upgrade on deploy_method (new)');
ok($dm->can('diff'),                         'diff on deploy_method (new)');
ok($dm->can('prepare_deploy'),               'prepare_deploy on deploy_method (no-op)');
ok($dm->can('prepare_upgrade'),              'prepare_upgrade on deploy_method (no-op)');
ok($dm->can('prepare_resultsource_install'), 'prepare_resultsource_install on deploy_method (no-op)');
ok($dm->can('initialize'),                   'initialize on deploy_method (no-op)');

# --- downgrade is unsupported --------------------------------------------

throws_ok { $dh->downgrade } qr/not supported/i,
  'downgrade croaks (not supported by native deploy)';

# --- upgrade flow with hooks ---------------------------------------------

{
  my @calls;

  my $dh = DBIO::DeploymentHandler->new({
    schema        => $schema,
    upgrade_hooks => {
      2 => {
        pre  => sub { push @calls, [pre  => 2, $_[1]{from}, $_[1]{to}] },
        post => sub { push @calls, [post => 2] },
      },
      3 => {
        post => sub { push @calls, [post => 3] },
      },
      5 => {
        # out of range — should not fire when going 1 -> 3
        pre  => sub { push @calls, [pre  => 5] },
        post => sub { push @calls, [post => 5] },
      },
    },
  });

  no warnings 'redefine';
  local *DBIO::DeploymentHandler::database_version
    = sub { 1 };
  local *DBIO::DeploymentHandler::schema_version
    = sub { 3 };
  local *DBIO::DeploymentHandler::add_database_version
    = sub { push @calls, [ver => $_[1]{version}, $_[1]{upgrade_sql}] };
  local *DBIO::DeploymentHandler::DeployMethod::Native::upgrade
    = sub { push @calls, ['ddl_apply']; undef };
  local *DBIO::DeploymentHandler::DeployMethod::Native::txn_do
    = sub { $_[1]->() };

  # F10: Test::Storage has no transactional_ddl capability (default 0),
  # so upgrade takes the non-transactional branch and emits BOTH the
  # "upgrading from N to M" announce AND a one-shot carp_once about the
  # non-atomic upgrade path. Capture both explicitly rather than using
  # warning_like, which only matches one warning at a time. The
  # transactional-branch behaviour is covered separately in
  # t/test/13_deploy_capabilities.t.
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $dh->upgrade;
  }
  ok( (grep { /\QDBIO::DeploymentHandler::upgrade(): upgrading from 1 to 3\E/ } @warnings),
    'upgrade announces from/to' );

  is_deeply \@calls, [
    [pre => 2, 1, 3],
    ['ddl_apply'],
    [post => 2],
    [post => 3],
    [ver  => 3, undef],
  ], 'pre hooks fire ascending before DDL, post hooks ascending after, version bumped to target';
}

# --- upgrade is no-op when already current -------------------------------

{
  my $dh = DBIO::DeploymentHandler->new({ schema => $schema });

  no warnings 'redefine';
  local *DBIO::DeploymentHandler::database_version = sub { 3 };
  local *DBIO::DeploymentHandler::schema_version   = sub { 3 };

  my $called = 0;
  local *DBIO::DeploymentHandler::DeployMethod::Native::upgrade
    = sub { $called++; undef };

  warning_like { $dh->upgrade } qr/no need to run upgrade/,
    'upgrade short-circuits when versions match';
  is $called, 0, 'deploy_method->upgrade not called on no-op';
}

# --- upgrade refuses to run backwards ------------------------------------

{
  my $dh = DBIO::DeploymentHandler->new({ schema => $schema });

  no warnings 'redefine';
  local *DBIO::DeploymentHandler::database_version = sub { 5 };
  local *DBIO::DeploymentHandler::schema_version   = sub { 3 };

  throws_ok { $dh->upgrade } qr/downgrade from 5 to 3 not supported/,
    'upgrade croaks when from > to';
}

# --- interface enforcement (assert_implemented) --------------------------
#
# Each of the three _init_* builders in DBIO::DeploymentHandler calls
# <Interface>->assert_implemented on the collaborator it constructs:
#   deploy_method   -> HandlesDeploy->assert_implemented
#   version_handler -> HandlesVersioning->assert_implemented
#   version_storage -> HandlesVersionStorage->assert_implemented
# A collaborator missing a required method must make construction fail LOUDLY,
# naming the missing method(s) and the interface -- not silently degrade.
#
# We exercise the contract through HandlesDeploy / deploy_method; the other two
# interfaces are structurally identical (same assert_implemented body, wired at
# their own _init_* site), so covering one proves the mechanism for all three.

# The full HandlesDeploy contract. make_deploy_stub builds a deploy-method
# stub class implementing this contract MINUS the named methods, so a test can
# prove the assertion fires and names exactly what is missing.
my @DEPLOY_CONTRACT = qw(
  prepare_deploy deploy prepare_resultsource_install
  install_resultsource prepare_upgrade txn_do upgrade
);

my $stub_counter = 0;
sub make_deploy_stub {
  my %omit = map { $_ => 1 } @_;
  my $pkg  = 'DBIO::Test::StubDeploy::N' . ++$stub_counter;
  no strict 'refs';
  *{"${pkg}::new"} = sub { bless {}, $pkg };
  *{"${pkg}::$_"}  = sub { } for grep { !$omit{$_} } @DEPLOY_CONTRACT;
  return $pkg;
}

{
  # deploy_method missing exactly one required method -> construction croaks,
  # naming that method and the interface it failed.
  my $stub = make_deploy_stub('upgrade');
  no warnings 'redefine';
  local *DBIO::DeploymentHandler::DeployMethod::Native::new
    = sub { $stub->new };

  throws_ok {
    DBIO::DeploymentHandler->new({ schema => $schema });
  } qr/HandlesDeploy interface: missing method\(s\).*\bupgrade\b/s,
    'construction croaks when deploy_method omits a required method, naming the method and the interface';
}

{
  # missing MORE than one -> the croak names ALL of them (deploy AND txn_do),
  # not just the first one encountered.
  my $stub = make_deploy_stub('deploy', 'txn_do');
  no warnings 'redefine';
  local *DBIO::DeploymentHandler::DeployMethod::Native::new
    = sub { $stub->new };

  throws_ok {
    DBIO::DeploymentHandler->new({ schema => $schema });
  } qr/missing method\(s\).*\bdeploy\b.*\btxn_do\b/s,
    'croak names ALL missing required methods, not just the first';
}

{
  # sanity: a stub implementing the FULL contract passes assert_implemented,
  # so construction lives -- the assertion is not a blanket failure.
  my $stub = make_deploy_stub();  # omit nothing
  no warnings 'redefine';
  local *DBIO::DeploymentHandler::DeployMethod::Native::new
    = sub { $stub->new };

  lives_ok {
    DBIO::DeploymentHandler->new({ schema => $schema });
  } 'construction lives when deploy_method satisfies the full HandlesDeploy contract';
}

done_testing();
