package DBIO::MySQL::Storage;
# ABSTRACT: MySQL storage layer for DBIO

use strict;
use warnings;

use base qw/DBIO::Storage::DBI/;

__PACKAGE__->register_driver('mysql' => __PACKAGE__);

# Async is an explicit, per-connection mode (core ADR 0030): a connection opened
# with connect(..., { async => 'ev' }) resolves the 'ev' mode through the mode
# registry to the native MySQL EV backend below. Registering on this driver
# storage class MRO-shadows the generic modes (forked/future_io) registered on
# the base storage, so 'ev' picks the MySQL-specific backend. There is no auto-
# fallback and no silent degrade: a mode that is neither requested nor registered
# is simply unavailable, and requesting an unregistered/uninstalled mode croaks
# (see DBIO::Storage::DBI::_async_storage). This only stores the class name --
# DBIO::MySQL::EV::Storage (the optional dbio-mysql-ev dist) is loaded lazily
# on first use, so registering it here is safe when the dist is absent.
__PACKAGE__->register_async_mode( ev => 'DBIO::MySQL::EV::Storage' );

# This is the ONLY async registration this driver needs, and it stays as-is
# under the storage-layer composition model (core karr #70): a mode maps to a
# transport BASE class, once, on this concrete driver storage. This dist writes
# storage_type only from its Schema components' connection() (DBIO::MySQL /
# DBIO::MySQL::MariaDB) -- choosing the driver BASE storage stays the driver's
# job. A driver EXTENSION does not subclass storage_type nor add a shadow
# register_async_mode / ::Async of its own: it registers a plain storage LAYER
# (DBIO::Schema::register_storage_layer) whose async mirror composes ON TOP of
# the resolved transport via DBIO::Storage::Composed. MySQL ships no such
# extension today, but the mechanism is core-provided and this reference driver
# honours it -- composition rides on top of this base; the mode->transport-base
# map does not grow per extension.

sub dbio_deploy_class { 'DBIO::MySQL::Deploy' }

__PACKAGE__->sql_maker_class('DBIO::MySQL::SQLMaker');
__PACKAGE__->sql_quote_char('`');
__PACKAGE__->datetime_parser_type('DateTime::Format::MySQL');

__PACKAGE__->_use_multicolumn_in(1);


sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  $self->_do_query('SET FOREIGN_KEY_CHECKS = 0');
  $sub->();
  $self->_do_query('SET FOREIGN_KEY_CHECKS = 1');
}


sub connect_call_set_strict_mode {
  my $self = shift;

  # the @@sql_mode puts back what was previously set on the session handle
  $self->_do_query(q|SET SQL_MODE = CONCAT('ANSI,TRADITIONAL,ONLY_FULL_GROUP_BY,', @@sql_mode)|);
  $self->_do_query(q|SET SQL_AUTO_IS_NULL = 0|);
}


sub _dbh_last_insert_id {
  my ($self) = @_;

  # default mysql_auto_reconnect to off unless explicitly set
  if (
    $self->_dbh->{mysql_auto_reconnect}
      and
    ! exists $self->_dbio_connect_attributes->{mysql_auto_reconnect}
  ) {
    $self->_dbh->{mysql_auto_reconnect} = 0;
  }

  $self->_dbh->{mysql_insertid};
}

# we need to figure out what mysql version we're running
sub sql_maker {
  my $self = shift;

  # it is critical to get the version *before* calling next::method
  # otherwise the potential connect will obliterate the sql_maker
  # next::method will populate in the _sql_maker accessor
  my $mysql_ver = $self->_server_info->{normalized_dbms_version};

  my $sm = $self->next::method(@_);

  # MySQL always uses backtick quoting — ensure it is active even when
  # the caller did not pass quote_names in connect_info.
  $sm->{quote_char} //= $self->sql_quote_char;
  $sm->{name_sep}   //= $self->sql_name_sep;

  # mysql 3 does not understand a bare JOIN
  $sm->{_default_jointype} = 'INNER' if $mysql_ver < 4;

  $sm;
}

sub sqlt_type {
  return 'MySQL';
}


sub deploy_defaults {
  return (add_drop_table => 1);
}


sub deploy_setup {
  my ($self, $schema) = @_;
  eval { $self->connect_call_set_zero_date_permissive };
}

sub connect_call_set_zero_date_permissive {
  my $self = shift;
  $self->_do_query(
    q{SET SESSION sql_mode = REPLACE(REPLACE(@@SESSION.sql_mode,'NO_ZERO_DATE',''),'NO_ZERO_IN_DATE','')}
  );
}


sub _random_function { 'RAND()' }

sub _explain_sql { "EXPLAIN $_[1]" }

sub deployment_statements {
  my $self = shift;
  my ($schema, $type, $version, $dir, $sqltargs, @rest) = @_;

  $sqltargs //= {};

  if (
    ! exists $sqltargs->{producer_args}{mysql_version}
      and
    my $dver = $self->_server_info->{normalized_dbms_version}
  ) {
    $sqltargs->{producer_args}{mysql_version} = $dver;
  }

  $self->next::method($schema, $type, $version, $dir, $sqltargs, @rest);
}


sub _exec_svp_begin {
    my ($self, $name) = @_;

    $self->_dbh->do("SAVEPOINT $name");
}

sub _exec_svp_release {
    my ($self, $name) = @_;

    $self->_dbh->do("RELEASE SAVEPOINT $name");
}

sub _exec_svp_rollback {
    my ($self, $name) = @_;

    $self->_dbh->do("ROLLBACK TO SAVEPOINT $name")
}

sub is_replicating {
    my $status = shift->_replication_status_row
      or return;
    return ($status->{Slave_IO_Running} eq 'Yes') && ($status->{Slave_SQL_Running} eq 'Yes');
}


sub lag_behind_master {
    my $status = shift->_replication_status_row
      or return undef;
    return $status->{Seconds_Behind_Master};
}


sub _replication_status_row {
    my $self = shift;
    return $self->_get_dbh->selectrow_hashref('SHOW SLAVE STATUS');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Storage - MySQL storage layer for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  # Optionally enable strict mode on connect
  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'set_strict_mode' },
  );

=head1 DESCRIPTION

MySQL storage backend for L<DBIO>. Extends L<DBIO::Storage::DBI> with
MySQL-specific behavior:

=over 4

=item *

Uses backtick quoting and C<LimitXY> pagination dialect.

=item *

Routes SQL generation through L<DBIO::MySQL::SQLMaker>.

=item *

Routes SQL generation through L<DBIO::MySQL::SQLMaker>, which
automatically wraps C<UPDATE> and C<DELETE> statements that reference
the modification target in a subquery.

=item *

Disables C<mysql_auto_reconnect> by default to prevent silent transaction
loss.

=back

This class is auto-registered for the C<mysql> DBI driver and is set as the
active storage class when L<DBIO::MySQL/connection> is called.

=head1 METHODS

=head2 with_deferred_fk_checks

  $storage->with_deferred_fk_checks(sub { ... });

Executes the given coderef with C<FOREIGN_KEY_CHECKS> disabled for the
duration of the call. Useful when loading data with circular foreign key
dependencies.

=head2 connect_call_set_strict_mode

  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'set_strict_mode' },
  );

Connection callback that enables C<ANSI>, C<TRADITIONAL>, and
C<ONLY_FULL_GROUP_BY> SQL modes and disables C<SQL_AUTO_IS_NULL>. Pass
C<set_strict_mode> as an C<on_connect_call> option to activate it.

=head2 deploy_defaults

MySQL has no transactional DDL and no C<IF NOT EXISTS> on all statement types.
Returns C<< add_drop_table => 1 >> so that L<DBIO::Test> can safely re-deploy
the same schema in a test sequence without hitting C<table already exists>
errors.

=head2 deploy_setup

Strips C<NO_ZERO_DATE> and C<NO_ZERO_IN_DATE> from the session C<sql_mode>
before deploying a schema during tests.  MySQL 8 strict mode rejects
C<0000-00-00> which the test suite uses to verify
C<datetime_undef_if_invalid> behaviour.

Delegates to L</connect_call_set_zero_date_permissive>. Note this only
relaxes the C<sql_mode> on the handle live at deploy time; when later
B<writes> (not just the deploy) must tolerate zero dates, wire
C<set_zero_date_permissive> through C<on_connect_call> instead so every
(re)connect inherits the relaxed mode.

=head2 connect_call_set_zero_date_permissive

  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'set_zero_date_permissive' },
  );

Strips C<NO_ZERO_DATE> and C<NO_ZERO_IN_DATE> from the session C<sql_mode>
so C<0000-00-00> can be written under MySQL 8 strict mode. Installed as an
C<on_connect_call> it re-runs on every (re)connect, so the session actually
issuing the writes -- not merely the connection alive at deploy time --
carries the relaxed mode. This is the seam L</deploy_setup> delegates to.

=head2 deployment_statements

Overrides the base implementation to automatically pass C<mysql_version> to
the SQL::Translator producer args when deploying a schema, so that generated
DDL is compatible with the connected server version.

=head2 is_replicating

Returns true if the connected MySQL replica is currently replicating from its
master (both IO and SQL threads running). Intended for use with
L<DBIO::Replicated::Storage>.

=head2 _replication_status_row

    my $row = $storage->_replication_status_row;

Returns the C<SHOW SLAVE STATUS> / C<SHOW REPLICA STATUS> row as a hashref,
or C<undef> when the connected server is not a replica. The default
implementation queries the legacy C<SHOW SLAVE STATUS> statement; the
MariaDB subclass tries the modern C<SHOW REPLICA STATUS> first and falls
back to the legacy statement.

This is the engine seam: anything that needs to read replication state
should go through here instead of issuing C<SHOW ... STATUS> itself.

=head2 lag_behind_master

Returns the number of seconds the replica is behind the master, as reported
by C<SHOW SLAVE STATUS>. Returns C<undef> if replication status is
unavailable.

=seealso

=over 4

=item * L<DBIO::MySQL> - Schema component that activates this storage

=item * L<DBIO::MySQL::SQLMaker> - SQL generation used by this storage

=item * L<DBIO::MySQL::Storage::MariaDB> - MariaDB-specific subclass

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
