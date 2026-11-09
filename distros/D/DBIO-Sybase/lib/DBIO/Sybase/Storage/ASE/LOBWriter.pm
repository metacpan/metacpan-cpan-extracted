package DBIO::Sybase::Storage::ASE::LOBWriter;
# ABSTRACT: LOB (TEXT/IMAGE) handling mixin for Sybase ASE

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Exception ();
use Try::Tiny;
use namespace::clean;

# No requires - these methods expect the consuming class to have:
# _is_lob_column, _get_dbh, _blob_log_on_update, _using_freetds

sub _is_lob_type {
  my ($self, $type) = @_;
  return unless defined $type;
  $type = lc $type;
  return $type =~ /^(?:text|ntext|image|blob|clob)$/;
}

# FreeTDS cannot write the content of a LOB: ct_data_info fails ("text pointer
# is not set or is undefined", live on FreeTDS 1.3.17), and it does so after
# the INSERT went out with its placeholder, so the row stood in the table
# without the value. Refused before anything is sent (karr k97). Only the
# content: NULL, '' and literal SQL need no write.
sub _refuse_lob_content {
  my ($self, $source, $col) = @_;
  return unless $self->_using_freetds;
  DBIO::Exception->throw(sprintf
    'DBIO::Sybase: table %s, column %s: writing a value into a TEXT or IMAGE '
    . 'column is refused: FreeTDS cannot write the content of a TEXT or IMAGE '
    . 'column (ct_data_info fails). Use a DBD::Sybase built against the Sybase '
    . 'Open Client libraries, or a VARCHAR column',
    $source->name, $col);
}

# Make sure blobs are not bound as placeholders, and return any non-empty ones
# as a hash.
#
# A value that already is literal SQL, a SCALAR ref, is neither replaced nor
# returned: it stays in the statement as it is (\'DEFAULT' of an empty insert,
# karr k80).
#
# What is left in place of a value is literal SQL, a SCALAR ref: NULL for
# undef, the empty string literal '' for every other value. It has to be the
# literal and not the two-character string "''": a string is a value, bound or
# (NoBindVars) quoted into the statement, and it stays the content of every
# LOB nothing is written to afterwards -- the ones set to '' (karr k72).
# ASE has no empty value: it stores '' as one space in a TEXT column and as
# the byte 0x20 in an IMAGE column.
sub _remove_blob_cols {
  my ($self, $source, $fields) = @_;

  # before anything is taken out of the caller's hash
  for my $col (sort keys %$fields) {
    next unless $self->_is_lob_column($source, $col);
    next if ref $fields->{$col} eq 'SCALAR';
    $self->_refuse_lob_content($source, $col)
      if defined $fields->{$col} and $fields->{$col} ne '';
  }

  my %blob_cols;

  for my $col (keys %$fields) {
    if ($self->_is_lob_column($source, $col)) {
      # literal SQL (karr k80): stays as it is, it is no content
      next if ref $fields->{$col} eq 'SCALAR';

      my $blob_val = delete $fields->{$col};
      if (not defined $blob_val) {
        $fields->{$col} = \'NULL';
      }
      else {
        $fields->{$col} = \"''";
        $blob_cols{$col} = $blob_val unless $blob_val eq '';
      }
    }
  }

  return %blob_cols ? \%blob_cols : undef;
}

# same for _insert_bulk, with the same two literals. Core's _insert_bulk takes
# a SCALAR ref in the first row as literal SQL for that column: it is no bind
# of the statement, nothing is read from the rows for it, and every other row
# has to carry the same literal ("Inconsistent literal SQL value" otherwise).
#
# So a column has ONE placeholder for all its rows (karr k81): NULL where no
# row has a value, the empty literal '' where at least one has. In the second
# case the rows that were undef are NULL only after the INSERT: they are
# recorded and set by _null_blobs_array, one UPDATE a row. The alternative,
# grouping the rows by literal into several _insert_bulk calls, would split
# the slice and break the assumption _insert_bulk makes to find the identities
# of the rows (the last one minus the number of rows, consecutive); here the
# slice stays one INSERT in the order it came in.
#
# Returns the content to write, by row and column, or undef for none. In list
# context the second value is the undef cells to set to NULL afterwards, by
# row and column (a true value in the cell), or undef for none.
sub _remove_blob_cols_array {
  my ($self, $source, $cols, $data) = @_;

  my (@blob_cols, @null_cols);

  for my $i (0..$#$cols) {
    next unless $self->_is_lob_column($source, $cols->[$i]);
    $self->_refuse_lob_content($source, $cols->[$i]) if grep {
      ref $_->[$i] ne 'SCALAR' and defined $_->[$i] and $_->[$i] ne ''
    } @$data;
  }

  for my $i (0..$#$cols) {
    my $col = $cols->[$i];

    if ($self->_is_lob_column($source, $col)) {
      # one placeholder for the column: '' as soon as a row has a value
      my $has_value = grep {
        ref $_->[$i] ne 'SCALAR' and defined $_->[$i]
      } @$data;

      for my $j (0..$#$data) {
        # literal SQL (karr k80): the cell stays as it is
        next if ref $data->[$j][$i] eq 'SCALAR';

        my $blob_val = delete $data->[$j][$i];
        if (not defined $blob_val) {
          if ($has_value) {
            $data->[$j][$i] = \"''";
            $null_cols[$j][$i] = 1;
          }
          else {
            $data->[$j][$i] = \'NULL';
          }
        }
        else {
          $data->[$j][$i] = \"''";
          $blob_cols[$j][$i] = $blob_val
            unless $blob_val eq '';
        }
      }
    }
  }

  my @ret = (
    (@blob_cols ? \@blob_cols : undef),
    (@null_cols ? \@null_cols : undef),
  );
  return wantarray ? @ret : $ret[0];
}

# The cells _remove_blob_cols_array left the empty literal in where the caller
# gave undef, set to NULL; $data has the primary key values of the rows.
sub _null_blobs_array {
  my ($self, $source, $null_cols, $cols, $data) = @_;

  my @primary_cols = $source->primary_columns;

  for my $j (0..$#$data) {
    next unless $null_cols->[$j];

    my %row;
    @row{ @$cols } = @{ $data->[$j] };

    $self->update(
      $source,
      { map { ($cols->[$_] => undef) } grep { $null_cols->[$j][$_] } 0..$#$cols },
      { map { ($_ => $row{$_}) } @primary_cols },
    );
  }
}

sub _update_blobs {
  my ($self, $source, $blob_cols, $where) = @_;

  my @primary_cols = try
    { $source->_pri_cols_or_die }
    catch {
      $self->throw_exception("Cannot update TEXT/IMAGE column(s): $_")
    };

  my @pks_to_update;
  if (
    ref $where eq 'HASH'
      and
    @primary_cols == grep { defined $where->{$_} } @primary_cols
  ) {
    my %row_to_update;
    @row_to_update{@primary_cols} = @{$where}{@primary_cols};
    @pks_to_update = \%row_to_update;
  }
  else {
    my $cursor = $self->select ($source, \@primary_cols, $where, {});
    @pks_to_update = map {
      my %row; @row{@primary_cols} = @$_; \%row
    } $cursor->all;
  }

  for my $ident (@pks_to_update) {
    $self->_insert_blobs($source, $blob_cols, $ident);
  }
}

sub _insert_blobs {
  my ($self, $source, $blob_cols, $row) = @_;
  my $dbh = $self->_get_dbh;

  my $table = $source->name;

  my %row = %$row;
  my @primary_cols = try
    { $source->_pri_cols_or_die }
    catch {
      $self->throw_exception("Cannot update TEXT/IMAGE column(s): $_")
    };

  $self->throw_exception('Cannot update TEXT/IMAGE column(s) without primary key values')
    if ((grep { defined $row{$_} } @primary_cols) != @primary_cols);

  # if we are 2-phase inserting a blob - there is nothing to retrieve anymore,
  # regardless of the previous state of the flag
  local $self->{_perform_autoinc_retrieval}
    if $self->_perform_autoinc_retrieval;

  for my $col (keys %$blob_cols) {
    my $blob = $blob_cols->{$col};

    my %where = map { ($_, $row{$_}) } @primary_cols;

    my $cursor = $self->select ($source, [$col], \%where, {});
    $cursor->next;
    my $sth = $cursor->sth;

    if (not $sth) {
      # the key columns, never their values
      $self->throw_exception(sprintf
        "Could not find row in table '%s' for blob update (key columns: %s)",
        $table, join(', ', @primary_cols),
      );
    }

    try {
      do {
        $sth->func('CS_GET', 1, 'ct_data_info') or die $sth->errstr;
      } while $sth->fetch;

      $sth->func('ct_prepare_send') or die $sth->errstr;

      my $log_on_update = $self->_blob_log_on_update;
      $log_on_update    = 1 if not defined $log_on_update;

      $sth->func('CS_SET', 1, {
        total_txtlen => length($blob),
        log_on_update => $log_on_update
      }, 'ct_data_info') or die $sth->errstr;

      $sth->func($blob, length($blob), 'ct_send_data') or die $sth->errstr;

      $sth->func('ct_finish_send') or die $sth->errstr;
    }
    catch {
      # the key values and the content are the values of this operation
      my $error = ref $_ ? $_ : $self->_mask_error_values(
        $_, [ grep { defined and !ref } values %row, $blob ],
      );
      if ($self->_using_freetds) {
        $self->throw_exception (
          "TEXT/IMAGE operation failed, probably because you are using FreeTDS: $error"
        );
      }
      else {
        $self->throw_exception($error);
      }
    }
    finally {
      $sth->finish if $sth;
    };
  }
}

sub _insert_blobs_array {
  my ($self, $source, $blob_cols, $cols, $data) = @_;

  for my $i (0..$#$data) {
    my $datum = $data->[$i];

    my %row;
    @row{ @$cols } = @$datum;

    my %blob_vals;
    for my $j (0..$#$cols) {
      if (exists $blob_cols->[$i][$j]) {
        $blob_vals{ $cols->[$j] } = $blob_cols->[$i][$j];
      }
    }

    $self->_insert_blobs ($source, \%blob_vals, \%row);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::ASE::LOBWriter - LOB (TEXT/IMAGE) handling mixin for Sybase ASE

=head1 VERSION

version 0.900004

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
