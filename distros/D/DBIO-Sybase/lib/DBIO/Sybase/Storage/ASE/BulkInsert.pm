package DBIO::Sybase::Storage::ASE::BulkInsert;
# ABSTRACT: Bulk insert API for Sybase ASE

use strict;
use warnings;
use Sub::Name();
use Try::Tiny;
use DBIO::Carp;
use namespace::clean;

# No requires - these methods expect the consuming class to have:
# _remove_blob_cols_array, _insert_blobs_array, _fetch_identity_sql,
# _autoinc_supplied_for_op, _bulk_storage, _get_dbh, _dbi_connect_info,
# _dbh_execute_for_fetch, sql_maker, txn_scope_guard, debug,
# _resolve_bindattrs, _query_end

sub _insert_bulk {
  my $self = shift;
  my ($source, $cols, $data) = @_;

  my $columns_info = $source->columns_info;

  my ($identity_col) =
    grep { $columns_info->{$_}{is_auto_increment} }
      keys %$columns_info;

  # FIXME - this is duplication from DBI.pm. When refactored towards
  # the LobWriter this can be folded back where it belongs.
  local $self->{_autoinc_supplied_for_op}
    = grep { $_ eq $identity_col } @$cols;

  my $use_bulk_api =
    $self->_bulk_storage &&
    $self->_get_dbh->{syb_has_blk};

  if (! $use_bulk_api and ref($self->_dbi_connect_info->[0]) eq 'CODE') {
    carp_unique( join ' ',
      'Bulk API support disabled due to use of a CODEREF connect_info.',
      'Reverting to regular array inserts.',
    );
  }

  if (not $use_bulk_api) {
    my $blob_cols = $self->_remove_blob_cols_array($source, $cols, $data);

# next::method uses a txn anyway, but it ends too early in case we need to
# select max(col) to get the identity for inserting blobs.
    ($self, my $guard) = $self->{transaction_depth} == 0 ?
      ($self->_writer_storage, $self->_writer_storage->txn_scope_guard)
      :
      ($self, undef);

    $self->next::method(@_);

    if ($blob_cols) {
      if ($self->_autoinc_supplied_for_op) {
        $self->_insert_blobs_array ($source, $blob_cols, $cols, $data);
      }
      else {
        my @cols_with_identities = (@$cols, $identity_col);

        ## calculate identities
        # XXX This assumes identities always increase by 1, which may or may not
        # be true.
        my ($last_identity) =
          $self->_dbh->selectrow_array (
            $self->_fetch_identity_sql($source, $identity_col)
          );
        my @identities = (($last_identity - @$data + 1) .. $last_identity);

        my @data_with_identities = map [@$_, shift @identities], @$data;

        $self->_insert_blobs_array (
          $source, $blob_cols, \@cols_with_identities, \@data_with_identities
        );
      }
    }

    $guard->commit if $guard;

    return;
  }

# otherwise, use the bulk API

# rearrange @$data so that columns are in database order
# and so we submit a full column list
  my %orig_order = map { $cols->[$_] => $_ } 0..$#$cols;

  my @source_columns = $source->columns;

  # bcp identity index is 1-based
  my ($identity_idx) = grep { $source_columns[$_] eq $identity_col } (0..$#source_columns);
  $identity_idx = defined $identity_idx ? $identity_idx + 1 : 0;

  my @new_data;
  for my $slice_idx (0..$#$data) {
    push @new_data, [map {
      # identity data will be 'undef' if not _autoinc_supplied_for_op()
      # columns with defaults will also be 'undef'
      exists $orig_order{$_}
        ? $data->[$slice_idx][$orig_order{$_}]
        : undef
    } @source_columns];
  }

  my $proto_bind = $self->_resolve_bindattrs(
    $source,
    [map {
      [ { dbic_colname => $source_columns[$_], _bind_data_slice_idx => $_ }
        => $new_data[0][$_] ]
    } (0 ..$#source_columns) ],
    $columns_info
  );

## Set a client-side conversion error handler, straight from DBD::Sybase docs.
# This ignores any data conversion errors detected by the client side libs, as
# they are usually harmless.
  my $orig_cslib_cb = DBD::Sybase::set_cslib_cb(
    Sub::Name::subname _insert_bulk_cslib_errhandler => sub {
      my ($layer, $origin, $severity, $errno, $errmsg, $osmsg, $blkmsg) = @_;

      return 1 if $errno == 36;

      carp
        "Layer: $layer, Origin: $origin, Severity: $severity, Error: $errno" .
        ($errmsg ? "\n$errmsg" : '') .
        ($osmsg  ? "\n$osmsg"  : '')  .
        ($blkmsg ? "\n$blkmsg" : '');

      return 0;
  });

  my $exception = '';
  try {
    my $bulk = $self->_bulk_storage;

    my $guard = $bulk->txn_scope_guard;

## FIXME - once this is done - address the FIXME on finish() below
## XXX get this to work instead of our own $sth
## will require SQLMaker or *Hacks changes for ordered columns
#    $bulk->next::method($source, \@source_columns, \@new_data, {
#      syb_bcp_attribs => {
#        identity_flag   => $self->_autoinc_supplied_for_op ? 1 : 0,
#        identity_column => $identity_idx,
#      }
#    });
    my $sql = 'INSERT INTO ' .
      $bulk->sql_maker->_quote($source->name) . ' (' .
# colname list is ignored for BCP, but does no harm
      (join ', ', map $bulk->sql_maker->_quote($_), @source_columns) . ') '.
      ' VALUES ('.  (join ', ', ('?') x @source_columns) . ')';

## XXX there's a bug in the DBD::Sybase bulk support that makes $sth->finish for
## a prepare_cached statement ineffective. Replace with ->sth when fixed, or
## better yet the version above. Should be fixed in DBD::Sybase .
    my $sth = $bulk->_get_dbh->prepare($sql,
#      'insert', # op
      {
        syb_bcp_attribs => {
          identity_flag   => $self->_autoinc_supplied_for_op ? 1 : 0,
          identity_column => $identity_idx,
        }
      }
    );

    {
      # FIXME the $sth->finish in _execute_array does a rollback for some
      # reason. Disable it temporarily until we fix the SQLMaker thing above
      no warnings 'redefine';
      no strict 'refs';
      local *{ref($sth).'::finish'} = sub {};

      $self->_dbh_execute_for_fetch(
        $source, $sth, $proto_bind, \@source_columns, \@new_data
      );
    }

    $guard->commit;

    $bulk->_query_end($sql);
  } catch {
    $exception = shift;
  };

  DBD::Sybase::set_cslib_cb($orig_cslib_cb);

  if ($exception =~ /-Y option/) {
    my $w = 'Sybase bulk API operation failed due to character set incompatibility, '
          . 'reverting to regular array inserts. Try unsetting the LANG environment variable'
    ;
    $w .= "\n$exception" if $self->debug;
    carp $w;

    $self->_bulk_storage(undef);
    unshift @_, $self;
    goto \&_insert_bulk;
  }
  elsif ($exception) {
# rollback makes the bulkLogin connection unusable
    $self->_bulk_storage->disconnect;
    $self->throw_exception($exception);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::ASE::BulkInsert - Bulk insert API for Sybase ASE

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
