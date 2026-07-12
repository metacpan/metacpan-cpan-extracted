package DBIO::Sybase::Storage::ASE;
# ABSTRACT: Sybase ASE SQL Server support for DBIO

use strict;
use warnings;

# The ASE::* trait classes below are standalone (no parent) and override
# methods that also exist in the deep DBIO::Storage::DBI hierarchy reached
# via DBIO::Sybase::Storage (e.g. last_insert_id, _execute, _insert_bulk,
# _exec_txn_begin). They MUST be listed before DBIO::Sybase::Storage so the
# C3 linearisation places them ahead of DBIO::Storage::DBI; otherwise their
# overrides are shadowed by core and never run (the trait methods chain into
# core via next::method).
use base qw/
  DBIO::Sybase::Storage::ASE::LOBWriter
  DBIO::Sybase::Storage::ASE::BulkInsert
  DBIO::Sybase::Storage::ASE::IdentityRetrieval
  DBIO::Sybase::Storage::ASE::TxnManager
  DBIO::Sybase::Storage
  DBIO::Storage::DBI::AutoCast
  DBIO::Storage::DBI::IdentityInsert
/;
use mro 'c3';
use DBIO::Carp;
use Scalar::Util qw/blessed weaken/;
use List::Util 'first';
use Sub::Name();
use Try::Tiny;
use Context::Preserve 'preserve_context';
use DBIO::Util 'sigwarn_silencer';
use version ();
use namespace::clean;


__PACKAGE__->sql_maker_class('DBIO::Sybase::SQLMaker');
__PACKAGE__->sql_quote_char ([qw/[ ]/]);
__PACKAGE__->datetime_parser_type(
  'DBIO::Sybase::Storage::ASE::DateTime::Format'
);

__PACKAGE__->mk_group_accessors('simple' =>
    qw/_identity _identity_method _blob_log_on_update _parent_storage
       _writer_storage _is_writer_storage
       _bulk_storage _is_bulk_storage _began_bulk_work
    /
);


my @also_proxy_to_extra_storages = qw/
  connect_call_set_auto_cast auto_cast connect_call_blob_setup
  connect_call_datetime_setup

  disconnect _connect_info _sql_maker _sql_maker_opts disable_sth_caching
  auto_savepoint unsafe cursor_class debug debugobj schema
/;


sub _rebless {
  my $self = shift;

  my $no_bind_vars = __PACKAGE__ . '::NoBindVars';

  if ($self->_using_freetds) {
    carp_once <<'EOF' unless $ENV{DBIO_SYBASE_FREETDS_NOWARN};

You are using FreeTDS with Sybase.

We will do our best to support this configuration, but please consider this
support experimental.

TEXT/IMAGE columns will definitely not work.

You are encouraged to recompile DBD::Sybase with the Sybase Open Client libraries
instead.

See perldoc DBIO::Sybase::Storage::ASE for more details.

To turn off this warning set the DBIO_SYBASE_FREETDS_NOWARN environment
variable.
EOF

    if (not $self->_use_typeless_placeholders) {
      if ($self->_use_placeholders) {
        $self->auto_cast(1);
      }
      else {
        $self->ensure_class_loaded($no_bind_vars);
        bless $self, $no_bind_vars;
        $self->_rebless;
      }
    }
  }

  elsif (not $self->_get_dbh->{syb_dynamic_supported}) {
    # not necessarily FreeTDS, but no placeholders nevertheless
    $self->ensure_class_loaded($no_bind_vars);
    bless $self, $no_bind_vars;
    $self->_rebless;
  }
  # this is highly unlikely, but we check just in case
  elsif (not $self->_use_typeless_placeholders) {
    $self->auto_cast(1);
  }
}

sub _init {
  my $self = shift;

  $self->next::method(@_);

  if (my $ver = $self->_using_freetds && $self->_using_freetds_version) {
    # Only the historic FreeTDS 0.8x line has the known statement-caching bug;
    # parse as a dotted version so 1.x is not coerced to a number (and no
    # "isn't numeric" warning is emitted).
    if (version->parse("v$ver") <= version->parse('v0.82')) {
      carp_once(
        "Buggy FreeTDS version $ver detected, statement caching will not work and "
      . 'will be disabled.'
      );
      $self->disable_sth_caching(1);
    }
  }

  $self->_set_max_connect(256);

# create storage for insert/(update blob) transactions,
# unless this is that storage
  return if $self->_parent_storage;

  my $writer_storage = (ref $self)->new;

  $writer_storage->_is_writer_storage(1); # just info
  $writer_storage->connect_info($self->connect_info);
  $writer_storage->auto_cast($self->auto_cast);

  weaken ($writer_storage->{_parent_storage} = $self);
  $self->_writer_storage($writer_storage);

# create a bulk storage unless connect_info is a coderef
  return if ref($self->_dbi_connect_info->[0]) eq 'CODE';

# FreeTDS' blk-library cannot do BCP ("Type '7' not implemented", and BULK
# INSERT is rejected inside the multi-statement txn DBD::Sybase keeps open).
# Without a bulk storage the _insert_bulk eligibility check falls back to
# regular array inserts, which is the only thing that works under FreeTDS.
  return if $self->_using_freetds;

  my $bulk_storage = (ref $self)->new;

  $bulk_storage->_is_bulk_storage(1); # for special ->disconnect acrobatics
  $bulk_storage->connect_info($self->connect_info);

# this is why
  $bulk_storage->_dbi_connect_info->[0] .= ';bulkLogin=1';

  weaken ($bulk_storage->{_parent_storage} = $self);
  $self->_bulk_storage($bulk_storage);
}

for my $method (@also_proxy_to_extra_storages) {
  no strict 'refs';
  no warnings 'redefine';

  my $replaced = __PACKAGE__->can($method);

  *{$method} = Sub::Name::subname $method => sub {
    my $self = shift;
    $self->_writer_storage->$replaced(@_) if $self->_writer_storage;
    $self->_bulk_storage->$replaced(@_)   if $self->_bulk_storage;
    return $self->$replaced(@_);
  };
}

sub disconnect {
  my $self = shift;

# Even though we call $sth->finish for uses off the bulk API, there's still an
# "active statement" warning on disconnect, which we throw away here.
# This is due to the bug described in _insert_bulk.
# Currently a noop because 'prepare' is used instead of 'prepare_cached'.
  local $SIG{__WARN__} = sigwarn_silencer(qr/active statement/i)
    if $self->_is_bulk_storage;

# so that next transaction gets a dbh
  $self->_began_bulk_work(0) if $self->_is_bulk_storage;

  $self->next::method;
}

# This is only invoked for FreeTDS drivers by ::Storage::DBI::Sybase::FreeTDS
sub _set_autocommit_stmt {
  my ($self, $on) = @_;

  return 'SET CHAINED ' . ($on ? 'OFF' : 'ON');
}

# Set up session settings for Sybase databases for the connection.
#
# Make sure we have CHAINED mode turned on if AutoCommit is off in non-FreeTDS
# DBD::Sybase (since we don't know how DBD::Sybase was compiled.) If however
# we're using FreeTDS, CHAINED mode turns on an implicit transaction which we
# only want when AutoCommit is off.
sub _run_connection_actions {
  my $self = shift;

  if ($self->_is_bulk_storage) {
    # this should be cleared on every reconnect
    $self->_began_bulk_work(0);
    return;
  }

  $self->_dbh->{syb_chained_txn} = 1
    unless $self->_using_freetds;

  $self->next::method(@_);
}


sub connect_call_blob_setup {
  my $self = shift;
  my %args = @_;
  my $dbh = $self->_dbh;
  $dbh->{syb_binary_images} = 1;

  $self->_blob_log_on_update($args{log_on_update})
    if exists $args{log_on_update};
}

sub _is_lob_column {
  my ($self, $source, $column) = @_;

  return $self->_is_lob_type($source->column_info($column)->{data_type});
}

sub _prep_for_execute {
  my ($self, $op, $ident, $args) = @_;

  my $limit;  # extract and use shortcut on limit without offset
  if ($op eq 'select' and ! $args->[4] and $limit = $args->[3]) {
    $args = [ @$args ];
    $args->[3] = undef;
  }

  my ($sql, $bind) = $self->next::method($op, $ident, $args);

  # $limit is already sanitized by now
  $sql = join( "\n",
    "SET ROWCOUNT $limit",
    $sql,
    "SET ROWCOUNT 0",
  ) if $limit;

  if (my $identity_col = $self->_perform_autoinc_retrieval) {
    $sql .= "\n" . $self->_fetch_identity_sql($ident, $identity_col)
  }

  return ($sql, $bind);
}

# Stolen from SQLT, with some modifications. This is a makeshift
# solution before a sane type-mapping library is available, thus
# the 'our' for easy overrides.
our %TYPE_MAPPING  = (
    number    => 'numeric',
    money     => 'money',
    varchar   => 'varchar',
    varchar2  => 'varchar',
    timestamp => 'datetime',
    text      => 'varchar',
    real      => 'double precision',
    comment   => 'text',
    bit       => 'bit',
    tinyint   => 'smallint',
    float     => 'double precision',
    serial    => 'numeric',
    bigserial => 'numeric',
    boolean   => 'varchar',
    long      => 'varchar',
);

sub _native_data_type {
  my ($self, $type) = @_;

  $type = lc $type;
  $type =~ s/\s* identity//x;

  return uc($TYPE_MAPPING{$type} || $type);
}

# handles TEXT/IMAGE and transaction for last_insert_id
sub insert {
  my $self = shift;
  my ($source, $to_insert) = @_;

  my $columns_info = $source->columns_info;

  my $identity_col =
    (first { $columns_info->{$_}{is_auto_increment} }
      keys %$columns_info )
    || '';

  # FIXME - this is duplication from DBI.pm. When refactored towards
  # the LobWriter this can be folded back where it belongs.
  local $self->{_autoinc_supplied_for_op} = exists $to_insert->{$identity_col}
    ? 1
    : 0
  ;
  local $self->{_perform_autoinc_retrieval} =
    ($identity_col and ! exists $to_insert->{$identity_col})
      ? $identity_col
      : undef
  ;

  # check for empty insert
  # INSERT INTO foo DEFAULT VALUES -- does not work with Sybase
  # try to insert explicit 'DEFAULT's instead (except for identity, timestamp
  # and computed columns)
  if (not %$to_insert) {
    for my $col ($source->columns) {
      next if $col eq $identity_col;

      my $info = $source->column_info($col);

      next if ref $info->{default_value} eq 'SCALAR'
        || (exists $info->{data_type} && (not defined $info->{data_type}));

      next if $info->{data_type} && $info->{data_type} =~ /^timestamp\z/i;

      $to_insert->{$col} = \'DEFAULT';
    }
  }

  my $blob_cols = $self->_remove_blob_cols($source, $to_insert);

  # do we need the horrific SELECT MAX(COL) hack?
  my $need_dumb_last_insert_id = (
    $self->_perform_autoinc_retrieval
      &&
    ($self->_identity_method||'') ne '@@IDENTITY'
  );

  my $next = $self->next::can;

  # we are already in a transaction, or there are no blobs
  # and we don't need the PK - just (try to) do it
  if ($self->{transaction_depth}
        || (!$blob_cols && !$need_dumb_last_insert_id)
  ) {
    return $self->_insert (
      $next, $source, $to_insert, $blob_cols, $identity_col
    );
  }

  # otherwise use the _writer_storage to do the insert+transaction on another
  # connection
  my $guard = $self->_writer_storage->txn_scope_guard;

  my $updated_cols = $self->_writer_storage->_insert (
    $next, $source, $to_insert, $blob_cols, $identity_col
  );

  $self->_identity($self->_writer_storage->_identity);

  $guard->commit;

  return $updated_cols;
}

sub _insert {
  my ($self, $next, $source, $to_insert, $blob_cols, $identity_col) = @_;

  my $updated_cols = $self->$next ($source, $to_insert);

  my $final_row = {
    ($identity_col ?
      ($identity_col => $self->last_insert_id($source, $identity_col)) : ()),
    %$to_insert,
    %$updated_cols,
  };

  $self->_insert_blobs ($source, $blob_cols, $final_row) if $blob_cols;

  return $updated_cols;
}

sub update {
  my $self = shift;
  my ($source, $fields, $where, @rest) = @_;

  #
  # When *updating* identities, ASE requires SET IDENTITY_UPDATE called
  #
  if (my $blob_cols = $self->_remove_blob_cols($source, $fields)) {

    # If there are any blobs in $where, Sybase will return a descriptive error
    # message.
    # XXX blobs can still be used with a LIKE query, and this should be handled.

    # update+blob update(s) done atomically on separate connection
    $self = $self->_writer_storage;

    my $guard = $self->txn_scope_guard;

    # First update the blob columns to be updated to '' (taken from $fields, where
    # it is originally put by _remove_blob_cols .)
    my %blobs_to_empty = map { ($_ => delete $fields->{$_}) } keys %$blob_cols;

    # We can't only update NULL blobs, because blobs cannot be in the WHERE clause.
    $self->next::method($source, \%blobs_to_empty, $where, @rest);

    # Now update the blobs before the other columns in case the update of other
    # columns makes the search condition invalid.
    my $rv = $self->_update_blobs($source, $blob_cols, $where);

    if (keys %$fields) {

      # Now set the identity update flags for the actual update
      local $self->{_autoinc_supplied_for_op} = grep
        { $_->{is_auto_increment} }
        values %{ $source->columns_info([ keys %$fields ]) }
      ;

      my $next = $self->next::can;
      my $args = \@_;
      return preserve_context {
        $self->$next(@$args);
      } after => sub { $guard->commit };
    }
    else {
      $guard->commit;
      return $rv;
    }
  }
  else {
    # Set the identity update flags for the actual update
    local $self->{_autoinc_supplied_for_op} = grep
      { $_->{is_auto_increment} }
      values %{ $source->columns_info([ keys %$fields ]) }
    ;

    return $self->next::method(@_);
  }
}


sub connect_call_datetime_setup {
  my $self = shift;
  my $dbh = $self->_get_dbh;

  if ($dbh->can('syb_date_fmt')) {
    # amazingly, this works with FreeTDS
    $dbh->syb_date_fmt('ISO_strict');
  }
  else {
    carp_once
      'Your DBD::Sybase is too old to support '
     .'DBIO::InflateColumn::DateTime, please upgrade!';

    $dbh->do('SET DATEFORMAT mdy');
  }
}


package DBIO::Sybase::Storage::ASE::DateTime::Format;

use base 'DBIO::Storage::DateTimeFormat';

# No preferred_format_class: DateTime::Format::Sybase expects mdy in both
# directions, but connect_call_datetime_setup configures ISO_strict output.
__PACKAGE__->datetime_parse_pattern('%Y-%m-%dT%H:%M:%S.%3NZ');
__PACKAGE__->datetime_format_pattern('%m/%d/%Y %H:%M:%S.%3N');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::ASE - Sybase ASE SQL Server support for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

    # Recommended connect_info settings for Sybase ASE:
    on_connect_call => [['datetime_setup'], ['blob_setup', log_on_update => 0]]

=head1 DESCRIPTION

Storage driver for Sybase ASE (Adaptive Server Enterprise) databases via
L<DBD::Sybase>.

If your Sybase version does not support placeholders, the storage is reblessed
to C<DBIO::Sybase::Storage::ASE::NoBindVars> automatically. FreeTDS connections
are supported but TEXT/IMAGE columns will not work; use the native Sybase
OpenClient libraries for full functionality.

Autoincrement retrieval is done via C<SELECT MAX(col)> inside a locked
transaction, as Sybase ASE provides no single-statement equivalent of
C<SCOPE_IDENTITY()>. TEXT/IMAGE (blob) columns require a separate write
operation on a dedicated connection and are handled transparently.

Bulk inserts use the L<DBD::Sybase> bulk API when available.

=head1 METHODS

=head2 connect_call_blob_setup

Used as:

  on_connect_call => [ [ 'blob_setup', log_on_update => 0 ] ]

Does C<< $dbh->{syb_binary_images} = 1; >> to return C<IMAGE> data as raw binary
instead of as a hex string.

Recommended.

Also sets the C<log_on_update> value for blob write operations. The default is
C<1>, but C<0> is better if your database is configured for it.

See
L<DBD::Sybase/Handling IMAGE/TEXT data with syb_ct_get_data()/syb_ct_send_data()>.

=head2 connect_call_datetime_setup

Used as:

  on_connect_call => 'datetime_setup'

In L<connect_info|DBIO::Storage::DBI/connect_info> to set:

  $dbh->syb_date_fmt('ISO_strict'); # output fmt: 2004-08-21T14:36:48.080Z
  $dbh->do('set dateformat mdy');   # input fmt:  08/13/1979 18:08:55.080

This works for both C<DATETIME> and C<SMALLDATETIME> columns, note that
C<SMALLDATETIME> columns only have minute precision.

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase> - Sybase schema component

=item * L<DBIO::Sybase::Storage> - Sybase storage dispatcher

=item * L<DBIO::Sybase::Storage::FreeTDS> - FreeTDS connection layer

=item * L<DBIO::Storage::DBI> - Base DBI storage class

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
