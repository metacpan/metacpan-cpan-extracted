package DBIO::Oracle::Type;
# ABSTRACT: Oracle type mapping utilities

use strict;
use warnings;



sub is_lob_type {
  my ($self, $dt) = @_;
  return unless $dt && $dt->can('sql_type');
  my $type = $dt->sql_type;
  return unless $type;
  return $type =~ /LOB\b/i;
}


sub is_text_lob_type {
  my ($self, $dt) = @_;
  return unless is_lob_type($self, $dt);
  my $type = $dt->sql_type;
  return $type =~ /CLOB\b/i;
}


sub oracle_lob_bind_attrs {
  my ($is_text) = @_;
  require DBD::Oracle;
  return {
    ora_type => $is_text ? DBD::Oracle::ORA_CLOB() : DBD::Oracle::ORA_BLOB(),
  };
}


sub normalize_type {
  my ($t) = @_;
  $t //= '';
  $t =~ s/\s+/ /g;
  return uc $t;
}


sub map_dbd_type_to_dbio {
  my ($data_type, %args) = @_;
  my $nchar_size_factor = $args{nchar_size_factor} // 1;

  $data_type //= '';
  my $lc_dt = lc $data_type;

  my %col = (data_type => $lc_dt);

  if ($lc_dt =~ /^(?:n(?:var)?char2?|u?rowid|nclob)\z/i) {
    $col{data_type} = $data_type;  # keep case for special types
    $col{size} = length($data_type) if $lc_dt =~ /^u?rowid\z/i;
  }
  elsif ($lc_dt =~ /^(?:n?[cb]lob|long(?: raw)?|bfile|date|binary_(?:float|double)|rowid)\z/i) {
    delete $col{size};
  }
  elsif ($lc_dt =~ /^n(?:var)?char2?\z/i) {
    $col{size} = $args{data_length} / $nchar_size_factor if $args{data_length};
  }
  elsif ($lc_dt =~ /^(?:var)?char2?\z/i) {
    $col{size} = $args{data_length};
  }
  elsif ($lc_dt =~ /^(number|decimal)\z/i) {
    $col{data_type} = 'numeric';
    if (defined $args{data_precision} && $args{data_precision} == 38
        && (!defined $args{data_scale} || $args{data_scale} == 0)) {
      $col{data_type} = 'integer';
    }
    elsif (defined $args{data_precision} && defined $args{data_scale}) {
      $col{size} = [$args{data_precision}, $args{data_scale}];
    }
    elsif (defined $args{data_precision}) {
      $col{size} = $args{data_precision};
    }
  }
  elsif (my ($precision) = $lc_dt =~ /^timestamp\((\d+)\)(?: with(?: local)? time zone)?\z/i) {
    $col{data_type} = $data_type =~ /time zone/i ? 'timestamp with time zone' : 'timestamp';
    $col{size} = $precision unless $precision == 6;
  }
  elsif ($lc_dt =~ /^interval year to month\z/i) {
    $col{data_type} = 'interval year to month';
    $col{size} = $args{data_precision} // 2;
  }
  elsif (my ($day_p, $sec_p) = $lc_dt =~ /^interval day\((\d+)\) to second\((\d+)\)\z/i) {
    $col{data_type} = 'interval day to second';
    $col{size} = [$day_p, $sec_p] unless ($day_p == 2 && $sec_p == 6);
  }
  elsif ($lc_dt eq 'float') {
    $col{data_type} = $args{data_length} <= 63 ? 'real' : 'double precision';
  }
  elsif ($lc_dt eq 'date') {
    $col{data_type} = 'datetime';
  }
  elsif ($lc_dt eq 'binary_float') {
    $col{data_type} = 'real';
  }
  elsif ($lc_dt eq 'binary_double') {
    $col{data_type} = 'double precision';
  }
  elsif ($lc_dt eq 'raw') {
    $col{size} = $args{data_length} / 2 if $args{data_length};
  }

  return \%col;
}


sub map_dbio_type_to_oracle {
  my ($type, %args) = @_;
  $type //= 'varchar2';
  my $lc = lc $type;

  my $size = $args{size};

  # Render a base type with its optional size, e.g. VARCHAR2(128) or
  # NUMBER(10,2). When no size is given, fall back to $default (which may
  # itself be undef for an unsized base type).
  my $sized = sub {
    my ($base, $default) = @_;
    my $spec = defined $size
      ? (ref $size eq 'ARRAY' ? join(',', @$size) : $size)
      : $default;
    return defined $spec && length $spec ? "$base($spec)" : $base;
  };

  # Numeric types
  return 'NUMBER' if $lc eq 'integer' || $lc eq 'bigint' || $lc eq 'smallint';
  return 'NUMBER(10)' if $lc eq 'serial';
  return 'NUMBER(20)' if $lc eq 'bigserial';

  # Character types
  return $sized->('VARCHAR2', 255) if $lc eq 'varchar';
  return $sized->('VARCHAR2', 255) if $lc eq 'nvarchar';
  return $sized->('CHAR', 1) if $lc eq 'char';
  return $sized->('NCHAR', 1) if $lc eq 'nchar';
  return 'CLOB' if $lc eq 'text' || $lc eq 'long';

  # Date/time types
  return 'DATE' if $lc eq 'date';
  return 'TIMESTAMP' if $lc eq 'timestamp' || $lc eq 'datetime';
  return 'TIMESTAMP WITH TIME ZONE' if $lc eq 'timestamptz' || $lc eq 'timestamp with time zone';

  # Binary types
  return 'BLOB' if $lc eq 'bytea' || $lc eq 'blob';
  return 'CLOB' if $lc eq 'clob';

  # Boolean
  return 'NUMBER(1)' if $lc eq 'boolean';

  # Float/double
  return 'BINARY_FLOAT' if $lc eq 'real';
  return 'BINARY_DOUBLE' if $lc eq 'float' || $lc eq 'double precision';

  # Numeric/decimal — size may be a scalar precision or [precision, scale]
  return $sized->('NUMBER') if $lc eq 'numeric' || $lc eq 'decimal';

  # Fallback — pass through uppercase
  return uc $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Type - Oracle type mapping utilities

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Consolidated Oracle type mapping logic used by L<DBIO::Oracle::Storage>,
L<DBIO::Oracle::DDL>, L<DBIO::Oracle::Introspect::Columns>, and
L<DBIO::Oracle::Diff::Column>.

The pure type-string functions (L</normalize_type>, L</map_dbio_type_to_oracle>,
L</map_dbd_type_to_dbio>) have no dependency on L<DBD::Oracle> and can be used
offline (e.g. by L<DBIO::Oracle::Diff>). Only L</oracle_lob_bind_attrs> pulls in
L<DBD::Oracle>, and it does so lazily at call time.

=func is_lob_type

    $self->is_lob_type($dt)

Returns true if the given L<Data::Type> is a LOB type (BLOB/CLOB/NCLOB).

=func is_text_lob_type

    $self->is_text_lob_type($dt)

Returns true if the LOB type is a text LOB (CLOB/NCLOB), false for binary.

=func oracle_lob_bind_attrs

    DBIO::Oracle::Type::oracle_lob_bind_attrs($is_text)

Returns the bind attributes for a LOB bind (ora_type => ORA_BLOB or ORA_CLOB).

=func normalize_type

    DBIO::Oracle::Type::normalize_type($type)

Normalizes an Oracle data type string for comparison (uppercase, collapse
whitespace).

=func map_dbd_type_to_dbio

    DBIO::Oracle::Type::map_dbd_type_to_dbio($data_type, %args)

Maps an Oracle data type string (from ALL_TAB_COLUMNS) to a DBIO canonical
type name. %args may include C<nchar_size_factor> for UTF-16 correction.

Returns a hashref with keys: C<data_type>, C<size>, C<not_null>, etc.

=func map_dbio_type_to_oracle

    DBIO::Oracle::Type::map_dbio_type_to_oracle($dbio_type, %args)

Maps a DBIO canonical type name to an Oracle DDL type string.
%args may include C<size> for VARCHAR2(n) etc.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
