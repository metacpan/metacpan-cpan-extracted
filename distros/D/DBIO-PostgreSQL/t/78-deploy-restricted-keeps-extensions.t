use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k89: a deploy restricted to certain PostgreSQL schemas
# (pg_schemas declared) creates missing extensions but drops none.
#
# WHY IT MATTERS: extensions are database-level objects. The pg_schemas
# restriction scopes everything else a deploy compares, but not extensions, so
# a deploy that manages only its own namespaces used to DROP EXTENSION every
# extension of the whole database it did not declare itself -- including ones
# other applications in the same database depend on. Maintainer decision
# (option a): a restricted deploy only adds extensions; an unrestricted deploy
# (no pg_schemas) owns the database and keeps dropping undeclared ones.
#
# WHAT IT PINS, through the real Deploy->diff with fixed live/desired models:
#   - restricted: an extension in the live database but not in the desired
#     model is NOT dropped; a desired one missing live IS created; a version
#     change of a declared one is still an update;
#   - unrestricted: the same models still produce the DROP EXTENSION;
#   - the diff engine itself is unchanged -- the rule belongs to the deploy,
#     a DBIO::PostgreSQL::Diff built by hand still drops.

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff;

# Live database: vector (undeclared, e.g. owned by another application) and
# pgcrypto at an old version.
my %LIVE = (
  vector   => { extension_name => 'vector',   version => '0.8.0' },
  pgcrypto => { extension_name => 'pgcrypto', version => '1.2' },
);
# Desired: pgcrypto (newer) and hstore (not yet installed).
my %DESIRED = (
  pgcrypto => { extension_name => 'pgcrypto', version => '1.3' },
  hstore   => { extension_name => 'hstore',   version => '1.8' },
);

{
  package DeployK89::Deploy;
  use base 'DBIO::PostgreSQL::Deploy';
  sub _introspect_current  { +{ extensions => { %LIVE } } }
  sub _build_target_model  { +{ extensions => { %DESIRED } } }
}
{
  package DeployK89::Restricted;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('app');
}
{
  package DeployK89::Unrestricted;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

sub ext_ops {
  my ($diff) = @_;
  return {
    map { $_->extension_name => $_->action }
    grep { $_->isa('DBIO::PostgreSQL::Diff::Extension') }
    @{ $diff->operations }
  };
}

# -----------------------------------------------------------------------
# 1. Restricted deploy: creates, updates, drops nothing
# -----------------------------------------------------------------------
{
  my $diff = DeployK89::Deploy->new(schema => 'DeployK89::Restricted')->diff;
  my $ops  = ext_ops($diff);

  ok !exists $ops->{vector},
    'restricted deploy does not drop an undeclared live extension';
  unlike $diff->as_sql, qr/DROP EXTENSION/, '... no DROP EXTENSION in its SQL';
  is $ops->{hstore}, 'create', '... but creates a declared missing one';
  is $ops->{pgcrypto}, 'update', '... and still updates a declared one';
  ok $diff->has_changes, '... so the diff has changes';
  is_deeply $diff->source->{extensions}, \%LIVE,
    '... while its source still reports the live database unchanged';
}

# -----------------------------------------------------------------------
# 2. Unrestricted deploy: drops as before
# -----------------------------------------------------------------------
{
  my $diff = DeployK89::Deploy->new(schema => 'DeployK89::Unrestricted')->diff;
  my $ops  = ext_ops($diff);

  is $ops->{vector}, 'drop', 'unrestricted deploy drops an undeclared live extension';
  like $diff->as_sql, qr/DROP EXTENSION vector;/, '... in its SQL';
  is $ops->{hstore}, 'create', '... and creates a declared missing one';
}

# -----------------------------------------------------------------------
# 3. The diff engine itself is unrestricted
# -----------------------------------------------------------------------
{
  my $diff = DBIO::PostgreSQL::Diff->new(
    source => { extensions => { %LIVE } },
    target => { extensions => { %DESIRED } },
  );
  is ext_ops($diff)->{vector}, 'drop',
    'a hand-built Diff still drops: the restriction is the deploy\'s';
}

# -----------------------------------------------------------------------
# 4. manage_extensions_when_restricted: the explicit way to let a
#    restricted deploy drop what it does not declare
# -----------------------------------------------------------------------
{
  my $diff = DeployK89::Deploy->new(
    schema => 'DeployK89::Restricted',
    manage_extensions_when_restricted => 1,
  )->diff;
  my $ops = ext_ops($diff);

  is $ops->{vector}, 'drop',
    'restricted deploy with manage_extensions_when_restricted drops the undeclared extension';
  like $diff->as_sql, qr/DROP EXTENSION vector;/, '... in its SQL';
  is $ops->{hstore}, 'create', '... and still creates a declared missing one';
  is $ops->{pgcrypto}, 'update', '... and still updates a declared one';
}
{
  my $diff = DeployK89::Deploy->new(
    schema => 'DeployK89::Restricted',
    manage_extensions_when_restricted => 0,
  )->diff;
  ok !exists ext_ops($diff)->{vector},
    'the switch set to 0 is the default: nothing dropped';
}
{
  my $diff = DeployK89::Deploy->new(
    schema => 'DeployK89::Unrestricted',
    manage_extensions_when_restricted => 1,
  )->diff;
  is ext_ops($diff)->{vector}, 'drop',
    'the switch changes nothing for an unrestricted deploy';
}

done_testing;
