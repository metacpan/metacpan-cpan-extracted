package DBIO::Sybase::Storage::ASE::LOBWriter;
# ABSTRACT: LOB (TEXT/IMAGE) handling mixin for Sybase ASE

use strict;
use warnings;
use DBIO::Util ();
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

# Make sure blobs are not bound as placeholders, and return any non-empty ones
# as a hash.
sub _remove_blob_cols {
  my ($self, $source, $fields) = @_;

  my %blob_cols;

  for my $col (keys %$fields) {
    if ($self->_is_lob_column($source, $col)) {
      my $blob_val = delete $fields->{$col};
      if (not defined $blob_val) {
        $fields->{$col} = \'NULL';
      }
      else {
        $fields->{$col} = "\'\'";
        $blob_cols{$col} = $blob_val unless $blob_val eq '';
      }
    }
  }

  return %blob_cols ? \%blob_cols : undef;
}

# same for _insert_bulk
sub _remove_blob_cols_array {
  my ($self, $source, $cols, $data) = @_;

  my @blob_cols;

  for my $i (0..$#$cols) {
    my $col = $cols->[$i];

    if ($self->_is_lob_column($source, $col)) {
      for my $j (0..$#$data) {
        my $blob_val = delete $data->[$j][$i];
        if (not defined $blob_val) {
          $data->[$j][$i] = \'NULL';
        }
        else {
          $data->[$j][$i] = "\'\'";
          $blob_cols[$j][$i] = $blob_val
            unless $blob_val eq '';
        }
      }
    }
  }

  return @blob_cols ? \@blob_cols : undef;
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
      $self->throw_exception(
          "Could not find row in table '$table' for blob update:\n"
        . DBIO::Util::dump_value(\%where)
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
      if ($self->_using_freetds) {
        $self->throw_exception (
          "TEXT/IMAGE operation failed, probably because you are using FreeTDS: $_"
        );
      }
      else {
        $self->throw_exception($_);
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

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
