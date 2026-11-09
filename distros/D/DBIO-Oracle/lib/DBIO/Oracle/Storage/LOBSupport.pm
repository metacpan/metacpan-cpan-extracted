package DBIO::Oracle::Storage::LOBSupport;
# ABSTRACT: LOB binding and chunking for Oracle

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp qw(carp);
use DBIO::Oracle::Type ();




# the parts of a text value: [ offset (1-based, in characters), text ]
sub _lob_text_parts {
  my ($data) = @_;
  my $offset = 1;
  return map { my $p = [ $offset, $_ ]; $offset += length $_; $p } unpack '(a1000)*', $data;
}

# the parts of a binary value: [ offset (1-based, in bytes), bytes ]
sub _lob_binary_parts {
  my ($data) = @_;
  my $offset = 1;
  return map { my $p = [ $offset, $_ ]; $offset += length $_; $p } unpack '(a2000)*', $data;
}

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
    # ADR 0008: the driver is loaded here, where a LOB is really bound
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

  if ($op eq 'insert') {
    my ($sql, $bind) = $self->next::method(@_);
    return $self->_wrap_lob_dml($sql, $bind);
  }

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

  return ($op eq 'update' ? $self->_wrap_lob_dml($sql, $bind, 'update') : ($sql, $bind))
    unless %$lob_bind_indices;

  my ($final_sql, @final_binds);
  if ($op eq 'update') {
    $self->throw_exception('Update with complex WHERE clauses involving BLOB columns currently not supported')
      if $sql =~ /\bWHERE\b .+ \bWHERE\b/xs;

    my $where_sql;
    ($final_sql, $where_sql) = $sql =~ /^ (.+?) ( \bWHERE\b .+) /xs;

    if (my $set_bind_count = $final_sql =~ y/?//) {
      delete $lob_bind_indices->{$_} for (0 .. ($set_bind_count - 1));
      return $self->_wrap_lob_dml($sql, $bind, 'update') unless %$lob_bind_indices;

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

      # What the LOB holds is compared in parts a SQL string can carry, with a
      # condition written for each part (see "Comparing a LOB by value").
      my $binary = ($bound->[0]{sqlt_datatype} // '') =~ /blob|bytea|image|raw|bfile/i;
      my @parts  = $binary ? _lob_binary_parts($data) : _lob_text_parts($data);
      my @sql_frag;

      if (!@parts) {
        # the empty string: an empty LOB, which has no part to compare
        push @sql_frag, sprintf 'DBMS_LOB.GETLENGTH(%s) = 0', $col;
      }
      else {
        for my $idx (0..$#parts) {
          push @sql_frag, $binary
            ? sprintf('DBMS_LOB.SUBSTR(%s, 2000, %d) = HEXTORAW(?)',
                $col, $parts[$idx][0])
            : sprintf('DBMS_LOB.SUBSTR(%s, 1000, %d) = ?',
                $col, $parts[$idx][0]);
        }
      }

      my $sql_frag = '( ' . (join ' AND ', @sql_frag) . ' )';
      $sql_parts[0] =~ s/$col_equality_re/$sql_frag/;

      $final_sql .= shift @sql_parts;

      for my $idx (0..$#parts) {
        push @final_binds, [
          { %{ $bound->[0] }, _ora_lob_autosplit_part => $idx, dbd_attrs => undef },
          $binary ? uc unpack('H*', $parts[$idx][1]) : $parts[$idx][1],
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
  return $op eq 'update'
    ? $self->_wrap_lob_dml($final_sql, \@final_binds, 'update')
    : ($final_sql, \@final_binds);
}

# see "INSERT and UPDATE with LOB values" above
sub _wrap_lob_dml {
  my ($self, $sql, $bind, $op) = @_;

  return ($sql, $bind) unless grep {
    my $b = $_->[0];
    ref $b eq 'HASH'
      and (
        ( $b->{dbd_attrs} and ref $b->{dbd_attrs} eq 'HASH' and exists $b->{dbd_attrs}{ora_type} )
          or
        ( !exists $b->{dbd_attrs} and $b->{sqlt_datatype} and $self->_is_lob_type($b->{sqlt_datatype}) )
      )
  } @$bind;

  return ("BEGIN $sql; END;", $bind) unless $op and $op eq 'update';

  # DBD::Oracle reports the row count of the block (always 1), not of the
  # UPDATE inside it. The block hands the real one back in an out bind.
  my $rc;
  $self->{_ora_lob_update_rowcount} = \$rc;
  return (
    "BEGIN $sql; ? := SQL%ROWCOUNT; END;",
    [ @$bind, [ { dbd_attrs => undef, dbd_size => 40 }, \$rc ] ],
  );
}


sub update {
  my $self = shift;

  local $self->{_ora_lob_update_rowcount};
  my $rv = $self->next::method(@_);

  my $rc = $self->{_ora_lob_update_rowcount};
  return $rv unless $rc and defined $$rc;
  return $$rc || '0E0';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage::LOBSupport - LOB binding and chunking for Oracle

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Handles Oracle LOB binding and chunked comparison logic.

=head1 METHODS

=head2 update

Returns the number of rows the C<UPDATE> changed, C<0E0> when none. When the
statement was sent as a block (see L</INSERT and UPDATE with LOB values>) the
count is the one the block read from C<SQL%ROWCOUNT>, so C<< $rs->update >>
and the "no row matched" check of C<< $row->update >> see the real number.

=head1 INSERT and UPDATE with LOB values

DBD::Oracle (1.95 and earlier, checked against Oracle 23ai) re-reads a LOB it
has just written, from the table and column names it takes out of the
C<INSERT>/C<UPDATE> text and I<upper-cases>. A table or a LOB column that was
created with a quoted lower-case or mixed-case name (what every quoting DBIO
schema does) is not found: the statement dies with ORA-01741 or ORA-00904
although the SQL itself is valid, and without C<ora_type> the same statement
dies with ORA-01465 or ORA-24816. The refetch only looks at statements that
begin with C<INSERT> or C<UPDATE>, so this storage sends every such statement
that binds a LOB inside an anonymous block, C<BEGIN ... ; END;>. The block runs
the same statement, C<RETURNING ... INTO> included, and DBD::Oracle binds the
LOB with C<ora_type> as before, but without the refetch. The upstream report
draft is C<maint/upstream/dbd-oracle-lob-refetch-quoted-identifiers.md>.

=head1 Comparing a LOB by value

A LOB cannot be compared with C<=> (ORA-22848), so a condition C<< { col =E<gt>
$value } >> on a LOB column is written as one comparison per part of the value,
joined with C<AND>, each on C<DBMS_LOB.SUBSTR> of the column.

=over 4

=item *

B<Text.> Parts of 1000 characters, compared as
C<DBMS_LOB.SUBSTR(col, 1000, offset) = ?>.
1000 and not the 2000 this module used to cut at: a SQL string holds 4000 bytes
and a character is up to 4 of them in the database's UTF-8, so 2000 Japanese
characters (6000 bytes) died with ORA-06502 at the fetch, on every row whose
column was longer. The amount is the same for every part, also the last, so that
a column that goes on beyond the value is not equal to it.

=item *

B<Binary.> Parts of 2000 bytes (what a C<RAW> holds), compared as
C<DBMS_LOB.SUBSTR(col, 2000, offset) = HEXTORAW(?)> with the part sent as hex:
the comparison used for text turns arbitrary bytes into other ones, so a binary
value was never found.

=item *

B<Empty.> An empty value is an empty LOB (not NULL: a LOB bound as C<''> is
stored empty), compared as C<< DBMS_LOB.GETLENGTH(col) = 0 >>; a column that is
NULL does not match.

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
