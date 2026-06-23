use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use DBIO::Test::Schema::Moo;
use DBIO::DeploymentHandler;

my $schema;
lives_ok {
  $schema = DBIO::Test::Schema::Moo->connect('DBIO::Test::Storage', '');
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

  warning_like { $dh->upgrade } qr/upgrading from 1 to 3/,
    'upgrade announces from/to';

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

done_testing();
