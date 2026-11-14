package DBIO::DeploymentHandler;
# ABSTRACT: Extensible DBIO deployment

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::DeploymentHandler::Dad';

use DBIO::Carp;
use DBIO::Exception;

use DBIO::DeploymentHandler::DeployMethod::Native;
use DBIO::DeploymentHandler::VersionHandler::Monotonic;
use DBIO::DeploymentHandler::VersionStorage::Standard;

use DBIO::DeploymentHandler::HandlesDeploy;
use DBIO::DeploymentHandler::HandlesVersioning;
use DBIO::DeploymentHandler::HandlesVersionStorage;

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
  DBIO::DeploymentHandler::HandlesDeploy->assert_implemented($self->{deploy_method});
  return $self->{deploy_method};
}

sub _init_version_handler {
  my ($self) = @_;
  # Only an explicitly given start (database_version alias or initial_version)
  # is forwarded -- the lazy default, the live database_version, would need the
  # version table at construction time (karr k214).
  $self->{version_handler} = DBIO::DeploymentHandler::VersionHandler::Monotonic->new({
    schema_version => $self->schema_version,
    initial_version => $self->{_dh_attrs}{initial_version} // $self->{initial_version},
    to_version => $self->to_version,
  });
  DBIO::DeploymentHandler::HandlesVersioning->assert_implemented($self->{version_handler});
  return $self->{version_handler};
}

sub _init_version_storage {
  my ($self) = @_;
  $self->{version_storage} = DBIO::DeploymentHandler::VersionStorage::Standard->new({
    schema => $self->schema,
    version_source => $self->version_source,
    version_class => $self->{version_class},
  });
  DBIO::DeploymentHandler::HandlesVersionStorage->assert_implemented($self->{version_storage});
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

    $diff = $self->deploy_method->upgrade(
      exists $args->{allow_destructive}
        ? { allow_destructive => $args->{allow_destructive} } : ()
    );

    $self->_run_hooks('post', $from, $to);

    my $upgrade_sql = ($diff && $diff->can('as_sql')) ? $diff->as_sql : undef;

    $self->add_database_version({
      version     => $to,
      ddl         => undef,
      upgrade_sql => $upgrade_sql,
    });
  };

  # F10: only wrap in txn_do when the engine can honour it. On engines
  # whose DDL forces an implicit COMMIT (MySQL and MariaDB on every
  # version, Oracle, Sybase, Informix), whose rebuild path depends on
  # AutoCommit=on (SQLite) or whose driver declines the capability
  # (DB2), the wrap is a no-op or a regression -- the body runs
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

version 0.900005

=head1 SYNOPSIS

  use DBIO::DeploymentHandler;

  # the schema must load the version-storage component -- it registers the
  # __VERSION result source that prepare_install / install rely on
  {
    package My::Schema;
    use DBIO 'Schema', -pg;
    __PACKAGE__->load_components('+DBIO::DeploymentHandler::VersionStorage::Standard::Component');
    __PACKAGE__->load_namespaces;
  }

  my $s = My::Schema->connect(...);

  my $dh = DBIO::DeploymentHandler->new({
    schema => $s,
    upgrade_hooks => {
      2 => {
        post => sub {
          my ($dh, $info) = @_;
          # backfill new column on the now-current schema
          $dh->schema->resultset('User')->update({ status => 'active' }, { all => 1 });
        },
      },
    },
  });

  $dh->prepare_install;   # does nothing with the native deploy method
  $dh->install;           # deploys schema, version table included, via native driver

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

Schema version is tracked in the C<dbio_deploymenthandler_versions> table
(result source C<__VERSION>).

This is a port of L<DBIx::Class::DeploymentHandler> adapted for DBIO's
native driver architecture.

=head1 ATTRIBUTES

=head2 initial_version

The version the database starts from: the C<database_version> constructor
argument, else an C<initial_version> argument, else (computed once and
cached) the current L</database_version>.

=head2 version_source

Name of the result source holding the version rows. Defaults to
C<__VERSION>, the source registered by
L<DBIO::DeploymentHandler::VersionStorage::Standard::Component>.

=head2 version_class

Result class of the version table. Defaults to
L<DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult>.

=head2 upgrade_hooks

Hashref of C<< { $version => { pre => $code, post => $code } } >> (default
empty). During L</upgrade>, every version C<$v> with C<< from < $v <= to >>
has its C<pre> hook called before the DDL reconcile and its C<post> hook
after it, in ascending version order, each as
C<< $code->($dh, { version, from, to, phase }) >>.

=head2 deploy_method

=head2 version_handler

=head2 version_storage

The three collaborator objects built by L</new>.

=head1 METHODS

=head2 new

  my $dh = DBIO::DeploymentHandler->new({
    schema        => $schema,          # required
    upgrade_hooks => { ... },          # optional, see DESCRIPTION
    to_version    => 3,                # optional, default: schema_version
    version_source => '__VERSION',     # optional
    version_class  => '...',           # optional
    txn_wrap      => 1,                # optional, default 1
  });

Takes a hashref or a flat list. On top of the L<DBIO::DeploymentHandler::Dad>
attributes it accepts C<database_version> as an alias for
C<initial_version>, C<upgrade_hooks>, C<version_source>, C<version_class> and
C<txn_wrap> (handed to the deploy method, see
L<DBIO::DeploymentHandler::DeployMethod::Native/txn_do>). Builds the three
collaborators -- L</deploy_method>
(L<DBIO::DeploymentHandler::DeployMethod::Native>), L</version_storage>
(L<DBIO::DeploymentHandler::VersionStorage::Standard>) and
L</version_handler> (L<DBIO::DeploymentHandler::VersionHandler::Monotonic>)
-- and checks each against its C<Handles*> interface, throwing if one is
incomplete.

=head2 prepare_deploy

=head2 deploy

=head2 prepare_resultsource_install

=head2 install_resultsource

=head2 prepare_upgrade

=head2 txn_do

Pass straight through to the same-named method of L</deploy_method>. With the
native deploy method C<deploy> installs the whole schema through the driver's
Deploy class, the C<prepare_*> methods and C<install_resultsource> do
nothing, and C<txn_do> runs its coderef in a transaction scope guard (unless
C<txn_wrap> is false).

=head2 upgrade

  my $diff = $dh->upgrade;
  my $diff = $dh->upgrade({ to_version => 3 });
  my $diff = $dh->upgrade({ allow_destructive => 1 });

The key C<allow_destructive> releases a diff that drops or may alter stored
data (L<DBIO::Deploy::Base/apply>); without it such a diff stops the upgrade
before its first statement.

Brings the database from L</database_version> to C<to_version> (default:
the schema version) in one shot: runs the C<pre> hooks, lets the driver
reconcile live database against the code (L</deploy_method>'s C<upgrade>),
runs the C<post> hooks, then records the new version together with the
diff's SQL (if the diff C<can('as_sql')>). Carps and returns nothing when
already at the target version; throws when asked to go backwards. The body
is wrapped in L</txn_do> only if the storage declares transactional DDL --
see L</TRANSACTIONAL UPGRADE>. Returns the driver's diff object.

=head2 downgrade

Always throws: the native deploy method diffs current code against the live
database and has no historical versions to go back to.

=head2 add_database_version

=head2 database_version

=head2 delete_database_version

=head2 version_storage_is_installed

Pass straight through to the same-named method of L</version_storage>; see
L<DBIO::DeploymentHandler::VersionStorage::Standard>.

=head2 next_version_set

=head2 previous_version_set

Pass straight through to the same-named method of L</version_handler>; see
L<DBIO::DeploymentHandler::VersionHandler::Monotonic>.

=head2 prepare_version_storage_install

Calls L</prepare_resultsource_install> for the version table's result source.

=head2 install_version_storage

  $dh->install_version_storage({ version => 2 });

Calls L</install_resultsource> for the version table's result source, with
C<version> defaulting to the schema version.

=head2 prepare_install

Calls L</prepare_deploy>, then L</prepare_version_storage_install>.

=head1 TRANSACTIONAL UPGRADE

L</upgrade> wraps the hook + DDL + version-bump body in
C<< $self->txn_do >> when the underlying storage reports
C<< _use_transactional_ddl >> truthy (see L<DBIO::Storage::DBI::Capabilities>).
A failure anywhere in the body rolls back both the DDL and the C<__VERSION>
row write.

On engines where DDL forces an implicit C<COMMIT> (MySQL and MariaDB on
every version, Oracle, Sybase, Informix), where the rebuild path depends on
C<AutoCommit=on> (SQLite), or whose driver deliberately declines the
capability (DB2) the wrap is skipped; see
L<DBIO::Deploy::Base/TRANSACTIONAL DDL>. In that case the C<__VERSION> row write is the
forward-progress gate: a partially applied upgrade can be re-run, the diff
re-computes against live state, and the next apply picks up the remainder.
A C<carp_once> is emitted at the first non-transactional upgrade naming
this storage class.

=head1 COMPATIBILITY: VERSION TABLE RENAME

B<The version-storage table was renamed from its inherited upstream name
C<dbix_class_deploymenthandler_versions> to C<dbio_deploymenthandler_versions>.>
This is a hard, one-way fork-rename with B<no automatic migration>: DBIO
looks only for the new name. Any database that was deployed with an older
DBIO (or with L<DBIx::Class::DeploymentHandler>) still carries the OLD table
and will look B<unversioned> to the current handler -- the connection-time
check will warn that the database is unversioned, and C<install> is not
refused either, since the handler does not see the old table.

If you have such a database, rename the existing table B<once, by hand>,
before connecting with the new DBIO. The DDL differs per engine; use the
form for your database:

  # PostgreSQL, SQLite, Oracle, MySQL/MariaDB -- standard ALTER TABLE ... RENAME TO
  ALTER TABLE dbix_class_deploymenthandler_versions
    RENAME TO dbio_deploymenthandler_versions;

  # MySQL/MariaDB also accept the dedicated statement:
  RENAME TABLE dbix_class_deploymenthandler_versions
    TO dbio_deploymenthandler_versions;

  # IBM DB2 -- RENAME TABLE (no ALTER ... RENAME form):
  RENAME TABLE dbix_class_deploymenthandler_versions
    TO dbio_deploymenthandler_versions;

  # Microsoft SQL Server -- stored procedure, not DDL:
  EXEC sp_rename 'dbix_class_deploymenthandler_versions',
                 'dbio_deploymenthandler_versions';

  # Sybase ASE -- sp_rename, same shape as SQL Server:
  sp_rename 'dbix_class_deploymenthandler_versions',
            'dbio_deploymenthandler_versions';

The C<ALTER TABLE ... RENAME TO> form is SQL-standard and is what most
engines the DBIO drivers target accept (PostgreSQL, SQLite, Oracle, and
MySQL/MariaDB). B<Engines whose syntax differs> are called out above:
DB2 has no C<ALTER ... RENAME> and uses C<RENAME TABLE>; SQL Server and
Sybase ASE rename through the C<sp_rename> stored procedure rather than DDL.
For any engine not listed, consult its manual for the table-rename
statement -- do not assume the C<ALTER TABLE> form works everywhere.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
