package DBIO::Oracle::Storage::LOBSupport;
# ABSTRACT: LOB binding and chunking for Oracle

use strict;
use warnings;

use Carp qw(carp);
use DBIO::Oracle::Type ();



sub _dbi_attrs_for_bind {
  my ($self, $ident, $bind) = @_;

  my $attrs = $self->next::method($ident, $bind);

  $attrs->[$_]
    and keys %{ $attrs->[$_] }
    and $bind->[$_][0]{dbic_colname}
    and $attrs->[$_] = { %{$attrs->[$_]}, ora_field => $bind->[$_][0]{dbic_colname} }
    for 0 .. $#$attrs;

  $attrs;
}

sub bind_attribute_by_data_type {
  my ($self, $dt) = @_;

  if ($self->_is_lob_type($dt)) {
    # DBD::Oracle is the live database driver: it is only needed when actually
    # binding a LOB against a real Oracle handle, never for SQL generation.
    # Loading it lazily here (as DBIO::Oracle::Type::oracle_lob_bind_attrs also
    # does) lets DBIO::Oracle::Storage load offline for SQL-generation tests.
    require DBD::Oracle;
    unless ($DBD::Oracle::__DBIO_DBD_VERSION_CHECK_OK__) {
      if ($DBD::Oracle::VERSION eq '1.23') {
        $self->throw_exception(
          "BLOB/CLOB support in DBD::Oracle == 1.23 is broken, use an earlier or later version "
          . "(https://rt.cpan.org/Public/Bug/Display.html?id=46016)"
        );
      }
      $DBD::Oracle::__DBIO_DBD_VERSION_CHECK_OK__ = 1;
    }

    return DBIO::Oracle::Type::oracle_lob_bind_attrs($self->_is_text_lob_type($dt));
  }
  return undef;
}

sub _prep_for_execute {
  my $self = shift;
  my ($op) = @_;

  return $self->next::method(@_) if $op eq 'insert';

  my ($sql, $bind) = $self->next::method(@_);

  my $lob_bind_indices = {
    map {
      (
        $bind->[$_][0]{sqlt_datatype}
          and
        $self->_is_lob_type($bind->[$_][0]{sqlt_datatype})
      ) ? ( $_ => 1 ) : ()
    } ( 0 .. $#$bind )
  };

  return ($sql, $bind) unless %$lob_bind_indices;

  my ($final_sql, @final_binds);
  if ($op eq 'update') {
    $self->throw_exception('Update with complex WHERE clauses involving BLOB columns currently not supported')
      if $sql =~ /\bWHERE\b .+ \bWHERE\b/xs;

    my $where_sql;
    ($final_sql, $where_sql) = $sql =~ /^ (.+?) ( \bWHERE\b .+) /xs;

    if (my $set_bind_count = $final_sql =~ y/?//) {
      delete $lob_bind_indices->{$_} for (0 .. ($set_bind_count - 1));
      return ($sql, $bind) unless %$lob_bind_indices;

      @final_binds = splice @$bind, 0, $set_bind_count;
      $lob_bind_indices = {
        map { $_ - $set_bind_count => $lob_bind_indices->{$_} }
          keys %$lob_bind_indices
      };
    }
    $sql = $where_sql;
  }
  elsif ($op ne 'select' and $op ne 'delete') {
    $self->throw_exception("Unsupported \$op: $op");
  }

  my @sql_parts = split /\?/, $sql;
  my $col_equality_re = qr/ (?<=\s) ([\w."]+) (\s*=\s*) $/x;

  for my $b_idx (0 .. $#$bind) {
    my $bound = $bind->[$b_idx];

    if ($lob_bind_indices->{$b_idx} and my ($col, $eq) = $sql_parts[0] =~ $col_equality_re) {
      my $data = $bound->[1];
      $data = "$data" if ref $data;

      my @parts = unpack '(a2000)*', $data;
      my @sql_frag;

      for my $idx (0..$#parts) {
        push @sql_frag, sprintf(
          'UTL_RAW.CAST_TO_VARCHAR2(RAWTOHEX(DBMS_LOB.SUBSTR(%s, 2000, %d))) = ?',
          $col, ($idx * 2000 + 1),
        );
      }

      my $sql_frag = '( ' . (join ' AND ', @sql_frag) . ' )';
      $sql_parts[0] =~ s/$col_equality_re/$sql_frag/;

      $final_sql .= shift @sql_parts;

      for my $idx (0..$#parts) {
        push @final_binds, [
          { %{ $bound->[0] }, _ora_lob_autosplit_part => $idx, dbd_attrs => undef },
          $parts[$idx],
        ];
      }
    }
    else {
      $final_sql .= shift(@sql_parts) . '?';
      push @final_binds, $lob_bind_indices->{$b_idx}
        ? [{ %{ $bound->[0] }, dbd_attrs => undef }, $bound->[1]]
        : $bound;
    }
  }

  if (@sql_parts > 1) {
    carp "There are more placeholders than binds, this should not happen!";
    @sql_parts = join('?', @sql_parts);
  }

  $final_sql .= $sql_parts[0];
  return ($final_sql, \@final_binds);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage::LOBSupport - LOB binding and chunking for Oracle

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Handles Oracle LOB binding and chunked comparison logic.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
