package DBIO::PostgreSQL::Storage;
# ABSTRACT: PostgreSQL storage layer for DBIO

use strict;
use warnings;

use base qw/DBIO::Storage::DBI/;

__PACKAGE__->register_driver('Pg' => __PACKAGE__);

sub dbio_deploy_class { 'DBIO::PostgreSQL::Deploy' }

__PACKAGE__->register_type('jsonb', {
  cake_options => [qw(inflate_json inflate_jsonb)],
  components   => ['InflateColumn::Serializer'],
  col_attrs    => { serializer_class => 'JSON' },
});


use Scope::Guard ();
use Context::Preserve 'preserve_context';
use DBIO::Carp;
use Try::Tiny;

# PostgreSQL defaults
__PACKAGE__->sql_maker_class('DBIO::PostgreSQL::SQLMaker');
__PACKAGE__->sql_quote_char('"');
__PACKAGE__->datetime_parser_type('DateTime::Format::Pg');
__PACKAGE__->_use_multicolumn_in(1);

# Async is an explicit, per-connection mode (core ADR 0030): a connection opened
# with connect(..., { async => 'ev' }) resolves the 'ev' mode through the mode
# registry to the native EV backend below. Registering on this driver storage
# class MRO-shadows the generic modes (forked/future_io) registered on the base
# storage, so 'ev' picks the PostgreSQL-specific backend. There is no auto-
# fallback and no silent degrade: a mode that is neither requested nor registered
# is simply unavailable, and requesting an unregistered/uninstalled mode croaks
# (see DBIO::Storage::DBI::_async_storage). This only stores the class name --
# DBIO::PostgreSQL::EV::Storage (the optional dbio-postgresql-ev dist) is loaded
# lazily on first use, so registering it here is safe when the dist is absent.
__PACKAGE__->register_async_mode( ev => 'DBIO::PostgreSQL::EV::Storage' );

# This is the ONLY async registration this driver needs, and it stays as-is
# under the storage-layer composition model (core karr #70): a mode maps to a
# transport BASE class, once, on this concrete driver storage. PostgreSQL
# EXTENSIONS (AGE, PostGIS, ...) no longer subclass storage_type nor add shadow
# register_async_mode / ::Async registrations -- they register plain storage
# LAYERS (DBIO::Schema::register_storage_layer) whose async mirrors compose ON
# TOP of the resolved transport via DBIO::Storage::Composed. Composition rides
# on top of this base; the mode->transport-base map does not grow per extension.

sub sql_maker {
  my $self = shift;
  my $sm = $self->next::method(@_);
  # PostgreSQL always uses double-quote identifier quoting — ensure it is
  # active even when the caller did not pass quote_names in connect_info.
  $sm->{quote_char} //= $self->sql_quote_char;
  $sm->{name_sep}   //= $self->sql_name_sep;
  $sm;
}

sub _determine_supports_insert_returning {
  return shift->_server_info->{normalized_dbms_version} >= 8.002
    ? 1
    : 0
  ;
}


sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  my $txn_scope_guard = $self->txn_scope_guard;

  $self->_do_query('SET CONSTRAINTS ALL DEFERRED');

  my $sg = Scope::Guard->new(sub {
    $self->_do_query('SET CONSTRAINTS ALL IMMEDIATE');
  });

  return preserve_context { $sub->() } after => sub { $txn_scope_guard->commit };
}


# only used when INSERT ... RETURNING is disabled
sub last_insert_id {
  my ($self, $source, @cols) = @_;

  my @values;
  my $col_info = $source->columns_info(\@cols);

  for my $col (@cols) {
    my $seq = ( $col_info->{$col}{sequence} ||= $self->dbh_do('_dbh_get_autoinc_seq', $source, $col) )
      or $self->throw_exception( sprintf(
        "Could not determine sequence for column '%s.%s', please consider adding a "
        . "schema-qualified sequence to its column info",
          $source->name,
          $col,
      ));

    push @values, $self->_dbh->last_insert_id(undef, undef, undef, undef, {sequence => $seq});
  }

  return @values;
}

sub _sequence_fetch {
  my ($self, $function, $sequence) = @_;

  $self->throw_exception('No sequence to fetch') unless $sequence;

  my ($val) = $self->_get_dbh->selectrow_array(
    sprintf("select %s('%s')", $function, (ref $sequence eq 'SCALAR') ? $$sequence : $sequence)
  );

  return $val;
}

sub _dbh_get_autoinc_seq {
  my ($self, $dbh, $source, $col) = @_;

  my $schema;
  my $table = $source->name;

  $table = $$table if ref $table eq 'SCALAR';

  if ($table =~ /^(.+)\.(.+)$/) {
    ($schema, $table) = ($1, $2);
  }

  my $seq_expr = $self->_dbh_get_column_default($dbh, $schema, $table, $col);

  unless (defined $seq_expr and $seq_expr =~ /^nextval\(+'([^']+)'::(?:text|regclass)\)/i) {
    $seq_expr = '' unless defined $seq_expr;
    $self->throw_exception( sprintf(
      "No sequence found for '%s%s.%s', check the RDBMS table definition or explicitly set the "
      . "'sequence' for this column in %s",
        $schema ? "$schema." : '',
        $table,
        $col,
        $source->source_name,
    ));
  }

  return $1;
}

sub _dbh_get_column_default {
  my ($self, $dbh, $schema, $table, $col) = @_;

  my $sqlmaker = $self->sql_maker;
  local $sqlmaker->{bindtype} = 'normal';

  my ($where, @bind) = $sqlmaker->where({
    'a.attnum'  => {'>', 0},
    'c.relname' => $table,
    'a.attname' => $col,
    -not_bool   => 'a.attisdropped',
    (defined $schema && length $schema)
      ? ('n.nspname' => $schema)
      : (-bool => \'pg_catalog.pg_table_is_visible(c.oid)')
  });

  my ($seq_expr) = $dbh->selectrow_array(<<"EOS", undef, @bind);

SELECT
  (SELECT pg_catalog.pg_get_expr(d.adbin, d.adrelid)
   FROM pg_catalog.pg_attrdef d
   WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef)
FROM pg_catalog.pg_class c
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
$where

EOS

  return $seq_expr;
}

sub sqlt_type { 'PostgreSQL' }

sub _explain_sql { "EXPLAIN ANALYZE $_[1]" }

sub _minmax_operator_for_datatype {
  #my ($self, $datatype, $want_max) = @_;

  return ($_[2] ? 'BOOL_OR' : 'BOOL_AND')
    if ($_[1] || '') =~ /\Abool(?:ean)?\z/i;

  shift->next::method(@_);
}


sub bind_attribute_by_data_type {
  my ($self, $data_type) = @_;

  if ($self->_is_binary_lob_type($data_type)) {
    unless ($DBD::Pg::__DBIO_DBD_VERSION_CHECK_DONE__) {
      if ($self->_server_info->{normalized_dbms_version} >= 9.0) {
        try { DBD::Pg->VERSION('2.17.2'); 1 } or carp(
          __PACKAGE__ . ': BYTEA columns are known to not work on Pg >= 9.0 with DBD::Pg < 2.17.2'
        );
      }
      elsif (not try { DBD::Pg->VERSION('2.9.2'); 1 }) { carp(
        __PACKAGE__ . ': DBD::Pg 2.9.2 or greater is strongly recommended for BYTEA column support'
      )}

      $DBD::Pg::__DBIO_DBD_VERSION_CHECK_DONE__ = 1;
    }

    return { pg_type => DBD::Pg::PG_BYTEA() };
  }
  else {
    return undef;
  }
}

# Savepoints via DBD::Pg native methods
sub _exec_svp_begin {
  my ($self, $name) = @_;
  $self->_dbh->pg_savepoint($name);
}

sub _exec_svp_release {
  my ($self, $name) = @_;
  $self->_dbh->pg_release($name);
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;
  $self->_dbh->pg_rollback_to($name);
}


# Override deployment to use DBIO::PostgreSQL::DDL instead of SQL::Translator
sub deploy {
  my ($self, $schema, $type, $sqltargs, $dir) = @_;

  if ($schema->can('pg_deploy')) {
    $schema->pg_deploy->install;
    return;
  }

  # Fallback to parent (SQL::Translator) for schemas without PostgreSQL component
  $self->next::method($schema, $type, $sqltargs, $dir);
}


sub deployment_statements {
  my $self = shift;
  my ($schema, $type, $version, $dir, $sqltargs, @rest) = @_;

  # If schema has PostgreSQL component, generate native DDL
  if ($schema->can('pg_install_ddl')) {
    return $schema->pg_install_ddl;
  }

  # Fallback to SQL::Translator
  $sqltargs ||= {};

  if (
    ! exists $sqltargs->{producer_args}{postgres_version}
      and
    my $dver = $self->_server_info->{normalized_dbms_version}
  ) {
    $sqltargs->{producer_args}{postgres_version} = $dver;
  }

  $self->next::method($schema, $type, $version, $dir, $sqltargs, @rest);
}



sub cake_defaults {
  return (
    inflate_jsonb     => 1,
    inflate_datetime  => 1,
    retrieve_defaults => 1,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Storage - PostgreSQL storage layer for DBIO

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::PostgreSQL::Storage> is the DBI storage class for PostgreSQL. It
extends L<DBIO::Storage::DBI> with PostgreSQL-specific behaviour:

=over 4

=item *

C<INSERT ... RETURNING> for efficient last-insert-id retrieval (PostgreSQL 8.2+).

=item *

Deferred foreign key checks via C<SET CONSTRAINTS ALL DEFERRED>.

=item *

Sequence lookup via C<pg_catalog> when C<RETURNING> is not available.

=item *

C<BYTEA> column binding through C<DBD::Pg> native type constants.

=item *

Native savepoint support via C<pg_savepoint>, C<pg_release>, and
C<pg_rollback_to>.

=item *

Deployment via L<DBIO::PostgreSQL::DDL> when the schema has the
L<DBIO::PostgreSQL> component loaded, falling back to SQL::Translator
otherwise.

=item *

Opt-in async via C<< MyApp::Schema->connect($dsn, $user, $pass, { async => 'ev' }) >>.
The C<ev> mode resolves (core ADR 0030 mode registry) to the native EV backend
from the optional L<DBIO::PostgreSQL::EV> dist, loaded lazily on first use. Without
that dist installed, requesting the mode croaks with a clear C<install> message —
there is no silent fallback or degrade.

=back

This class is registered as the driver for the C<Pg> DBD and is selected
automatically when L<DBIO::PostgreSQL> is loaded into a schema class.
Schema-introspection and migration planning live in
L<DBIO::PostgreSQL::Introspect>, L<DBIO::PostgreSQL::Diff>, and
L<DBIO::PostgreSQL::Deploy>; this class stays focused on the live DBI storage
behaviour.

=head1 METHODS

=head2 with_deferred_fk_checks

    $storage->with_deferred_fk_checks(sub { ... });

Wraps the given coderef in a transaction with C<SET CONSTRAINTS ALL DEFERRED>,
restoring immediate constraint checking afterwards. Use this when bulk-loading
data that temporarily violates referential integrity.

=head2 last_insert_id

    my @ids = $storage->last_insert_id($source, @cols);

Returns the last inserted value(s) for the given column(s) by querying the
associated sequence via C<pg_catalog>. Only called when C<INSERT ... RETURNING>
is unavailable (PostgreSQL older than 8.2). The sequence is determined from the
column default expression.

=head2 bind_attribute_by_data_type

    my $attr = $storage->bind_attribute_by_data_type($data_type);

Returns C<{ pg_type =E<gt> DBD::Pg::PG_BYTEA() }> for binary LOB types so that
C<DBD::Pg> handles C<BYTEA> columns correctly. Also checks that a compatible
C<DBD::Pg> version is installed for the connected PostgreSQL server version.

=head2 deploy

    $storage->deploy($schema, $type, $sqltargs, $dir);

Deploys the schema. When the schema has the L<DBIO::PostgreSQL> component
loaded (i.e. C<$schema-E<gt>can('pg_deploy')> is true), delegates to
L<DBIO::PostgreSQL::Deploy/install>. Otherwise falls back to the parent
SQL::Translator-based deployment.

=head2 deployment_statements

    my $sql = $storage->deployment_statements($schema, ...);

Generates DDL statements for deployment. When the schema has
C<pg_install_ddl>, returns native PostgreSQL DDL from
L<DBIO::PostgreSQL::DDL>. Otherwise falls back to SQL::Translator, passing
the detected server version as C<postgres_version> to the producer.

=head2 cake_defaults

Returns PostgreSQL-optimized defaults for L<DBIO::Cake>.
Activated via C<use DBIO::Cake '-Pg'>.

=over 4

=item * C<inflate_jsonb> — on (PostgreSQL standard is jsonb, not json)

=item * C<inflate_datetime> — on

=item * C<retrieve_defaults> — on (PostgreSQL generates UUIDs, serials, NOW(), etc.)

=back

=seealso

=over 4

=item * L<DBIO::PostgreSQL> - schema component that activates this storage class

=item * L<DBIO::PostgreSQL::Deploy> - high-level deploy/upgrade orchestration

=item * L<DBIO::PostgreSQL::DDL> - native PostgreSQL DDL generator

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
