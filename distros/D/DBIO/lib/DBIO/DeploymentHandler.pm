package DBIO::DeploymentHandler;
# ABSTRACT: Extensible DBIO deployment

use strict;
use warnings;

use base 'DBIO::DeploymentHandler::Dad';

use DBIO::Carp;
use DBIO::Exception;

use DBIO::DeploymentHandler::DeployMethod::Native;
use DBIO::DeploymentHandler::VersionHandler::Monotonic;
use DBIO::DeploymentHandler::VersionStorage::Standard;

use namespace::clean;


sub new {
  my ($class, @args) = @_;
  my $args = @args == 1 ? $args[0] : { @args };
  my $self = $class->SUPER::new($args);
  $self->{_dh_attrs} ||= {};

  # Support database_version as alternative to initial_version
  unless (exists $self->{_dh_attrs}{initial_version}) {
    if (exists $args->{database_version}) {
      $self->{_dh_attrs}{initial_version} = $args->{database_version};
    }
  }

  # Initialize sub-objects
  $self->_init_deploy_method;
  $self->_init_version_storage;
  $self->_init_version_handler;

  # Force version_storage to be eagerly loaded
  $self->version_storage;

  return $self;
}

sub _init_deploy_method {
  my ($self) = @_;
  $self->{deploy_method} = DBIO::DeploymentHandler::DeployMethod::Native->new({
    schema => $self->schema,
    schema_version => $self->schema_version,
    version_source => $self->version_source,
    txn_wrap => $self->{txn_wrap} // 1,
  });
  return $self->{deploy_method};
}

sub _init_version_handler {
  my ($self) = @_;
  $self->{version_handler} = DBIO::DeploymentHandler::VersionHandler::Monotonic->new({
    schema_version => $self->schema_version,
    initial_version => $self->{_dh_attrs}{initial_version},
    to_version => $self->to_version,
  });
  return $self->{version_handler};
}

sub _init_version_storage {
  my ($self) = @_;
  $self->{version_storage} = DBIO::DeploymentHandler::VersionStorage::Standard->new({
    schema => $self->schema,
    version_source => $self->version_source,
    version_class => $self->{version_class},
  });
  return $self->{version_storage};
}

# Attributes
sub initial_version {
  my $self = shift;
  return $self->{_dh_attrs}{initial_version} if exists $self->{_dh_attrs}{initial_version};
  return $self->{initial_version} if exists $self->{initial_version};
  $self->{_dh_attrs}{initial_version} = $self->database_version;
  return $self->{_dh_attrs}{initial_version};
}

sub version_source {
  my $self = shift;
  return $self->{version_source} if exists $self->{version_source};
  return '__VERSION';
}

sub version_class {
  my $self = shift;
  return $self->{version_class} if exists $self->{version_class};
  return 'DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult';
}

sub upgrade_hooks {
  my $self = shift;
  return $self->{upgrade_hooks} ||= {};
}

# Sub-object accessors
sub deploy_method { $_[0]->{deploy_method} }
sub version_handler { $_[0]->{version_handler} }
sub version_storage { $_[0]->{version_storage} }

# Passthrough methods to deploy_method
sub prepare_deploy {
  my $self = shift;
  $self->deploy_method->prepare_deploy(@_);
}

sub deploy {
  my $self = shift;
  $self->deploy_method->deploy(@_);
}

sub prepare_resultsource_install {
  my $self = shift;
  $self->deploy_method->prepare_resultsource_install(@_);
}

sub install_resultsource {
  my $self = shift;
  $self->deploy_method->install_resultsource(@_);
}

sub prepare_upgrade {
  my $self = shift;
  $self->deploy_method->prepare_upgrade(@_);
}

sub txn_do {
  my $self = shift;
  $self->deploy_method->txn_do(@_);
}

# Native deploy reconciles the whole schema in one shot. Override Dad's
# version-step loop with a single deploy_method->upgrade call, framed by
# per-version pre/post hooks for any data migrations the DDL diff cannot
# express.
sub upgrade {
  my $self = shift;
  my $args = shift || {};

  my $from = $self->database_version;
  my $to   = $args->{to_version} // $self->schema_version;
  $from = ref($from) ? $from->numify : $from;
  $to   = ref($to)   ? $to->numify   : $to;

  if ($from == $to) {
    carp('no need to run upgrade');
    return;
  }
  DBIO::Exception->throw("downgrade from $from to $to not supported by native deploy")
    if $from > $to;

  carp("upgrading from $from to $to");

  my $diff;
  my $body = sub {
    $self->_run_hooks('pre', $from, $to);

    $diff = $self->deploy_method->upgrade;

    $self->_run_hooks('post', $from, $to);

    my $upgrade_sql = ($diff && $diff->can('as_sql')) ? $diff->as_sql : undef;

    $self->add_database_version({
      version     => $to,
      ddl         => undef,
      upgrade_sql => $upgrade_sql,
    });
  };

  # F10: only wrap in txn_do when the engine can honour it. On engines
  # whose DDL forces an implicit COMMIT (MySQL pre-8.0, Oracle, DB2,
  # Sybase, Informix) or whose rebuild path depends on AutoCommit=on
  # (SQLite), the wrap is a no-op or a regression -- the body runs
  # statement-at-a-time and the __VERSION row gate is the forward-progress
  # recovery story.
  if ($self->_storage_uses_transactional_ddl) {
    $self->txn_do($body);
  }
  else {
    carp_once("non-transactional upgrade on @{[ ref($self->schema->storage) || $self->schema->storage ]} -- upgrade is not atomic; recovery depends on the __VERSION row gate");
    $body->();
  }

  return $diff;
}

# F10: helper that probes the storage's transactional_ddl capability. False
# when the storage is missing, the capability is unset, or the storage
# reports it as 0. Drivers register via _use_transactional_ddl(1|0) in
# L<DBIO::Storage::DBI::Capabilities>.
sub _storage_uses_transactional_ddl {
  my ($self) = @_;
  my $storage = eval { $self->schema->storage } || return 0;
  return 0 unless $storage->can('_use_transactional_ddl');
  return $storage->_use_transactional_ddl ? 1 : 0;
}

sub downgrade {
  DBIO::Exception->throw(
    'downgrade is not supported by the native DBIO deploy method '
    . '(driver diffs current code vs. live DB, not historical versions)'
  );
}

sub _run_hooks {
  my ($self, $phase, $from, $to) = @_;
  my $hooks = $self->upgrade_hooks;
  return unless %$hooks;

  for my $version (sort { $a <=> $b } keys %$hooks) {
    next unless $version > $from && $version <= $to;
    my $hook = $hooks->{$version}{$phase} or next;
    $hook->($self, {
      version => $version,
      from    => $from,
      to      => $to,
      phase   => $phase,
    });
  }
}

# Passthrough methods to version_storage
sub add_database_version {
  my $self = shift;
  $self->version_storage->add_database_version(@_);
}

sub database_version {
  my $self = shift;
  $self->version_storage->database_version(@_);
}

sub delete_database_version {
  my $self = shift;
  $self->version_storage->delete_database_version(@_);
}

sub version_storage_is_installed {
  my $self = shift;
  $self->version_storage->version_storage_is_installed(@_);
}

# Passthrough methods to version_handler
sub next_version_set {
  my $self = shift;
  $self->version_handler->next_version_set(@_);
}

sub previous_version_set {
  my $self = shift;
  $self->version_handler->previous_version_set(@_);
}

# Orthogonal methods
sub prepare_version_storage_install {
  my $self = shift;
  $self->prepare_resultsource_install({
    result_source => $self->version_storage->version_rs->result_source
  });
}

sub install_version_storage {
  my $self = shift;
  my $version = (shift || {})->{version} || $self->schema_version;
  $self->install_resultsource({
    result_source => $self->version_storage->version_rs->result_source,
    version => $version,
  });
}

sub prepare_install {
  $_[0]->prepare_deploy;
  $_[0]->prepare_version_storage_install;
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler - Extensible DBIO deployment

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  use DBIO::DeploymentHandler;
  my $s = My::Schema->connect(...);

  my $dh = DBIO::DeploymentHandler->new({
    schema => $s,
    upgrade_hooks => {
      2 => {
        post => sub {
          my ($dh, $info) = @_;
          # backfill new column on the now-current schema
          $dh->schema->resultset('User')->update({ status => 'active' });
        },
      },
    },
  });

  $dh->prepare_install;   # sets up __VERSION table
  $dh->install;           # deploys schema via native driver

  # later:
  $dh->upgrade;           # one-shot reconcile + run hooks for skipped versions

See F<t/deployment_handler.t> for a runnable example.

=head1 DESCRIPTION

DBIO::DeploymentHandler provides schema deployment and version management
using the native DBIO driver deploy system (no SQL::Translator needed).

The driver computes the diff between live database and current code in one
shot, so this handler does not loop over discrete version transitions the
way L<DBIx::Class::DeploymentHandler> does. The DDL part of an upgrade is
always a single reconcile.

For data migrations that the DDL diff cannot express (column backfills,
value normalisation, etc.) C<upgrade_hooks> provides per-version C<pre>
and C<post> callbacks that fire around the DDL apply, in ascending version
order, for every version step that is being crossed. C<pre> hooks see the
old schema, C<post> hooks see the new one.

Schema version is tracked in a C<__VERSION> table.

This is a port of L<DBIx::Class::DeploymentHandler> adapted for DBIO's
native driver architecture.

=head1 TRANSACTIONAL UPGRADE

L</upgrade> wraps the hook + DDL + version-bump body in
C<< $self->txn_do >> when the underlying storage reports
C<< _use_transactional_ddl >> truthy (see L<DBIO::Storage::DBI::Capabilities>).
A failure anywhere in the body rolls back both the DDL and the C<__VERSION>
row write.

On engines where DDL forces an implicit C<COMMIT> (MySQL pre-8.0 without
transactional DDL, Oracle, DB2, Sybase, Informix) or where the rebuild path
depends on C<AutoCommit=on> (SQLite) the wrap is skipped -- the engine
cannot honour it. In that case the C<__VERSION> row write is the
forward-progress gate: a partially applied upgrade can be re-run, the diff
re-computes against live state, and the next apply picks up the remainder.
A C<carp_once> is emitted at the first non-transactional upgrade naming
this storage class.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
