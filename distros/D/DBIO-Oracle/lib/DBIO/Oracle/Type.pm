package DBIO::Oracle::Type;
# ABSTRACT: Oracle type mapping utilities

use strict;
use warnings;

use DBIO::Exception ();

our $VERSION = '0.900004';



sub is_lob_type {
  my ($self, $dt) = @_;
  $dt && ($dt =~ /lob|bfile|text|image|bytea|memo/i
    || $dt =~ /^long(?:\s+(?:raw|bit\s*varying|varbit|binary
                              |varchar|character\s*varying|nvarchar
                              |national\s*character\s*varying))?\z/xi);
}


sub is_text_lob_type {
  my ($self, $dt) = @_;
  $dt && ($dt =~ /^(?:n?clob|memo)\z/i
    || $dt =~ /^long(?:\s+(?:varchar|character\s*varying|nvarchar
                        |national\s*character\s*varying))\z/xi);
}


sub oracle_lob_bind_attrs {
  my ($is_text) = @_;
  # DBD::Oracle is loaded lazily: this function only runs for real LOB binds,
  # i.e. with a live database connection, where DBD::Oracle must be present.
  # Loading it at compile time would make every offline user of this module
  # (e.g. DBIO::Oracle::Diff::Column) fail on hosts without DBD::Oracle.
  require DBD::Oracle;
  return {
    ora_type => $is_text ? DBD::Oracle::ORA_CLOB() : DBD::Oracle::ORA_BLOB(),
  };
}


sub render_default_value {
  my ($dv) = @_;
  return undef unless defined $dv;
  return $$dv if ref $dv eq 'SCALAR';
  return "$dv" if $dv =~ /\A(?:0|-?[1-9][0-9]*(?:\.[0-9]*[1-9])?|-?0\.[0-9]*[1-9])\z/;
  (my $lit = $dv) =~ s/'/''/g;
  return "'$lit'";
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
    # NCHAR and NVARCHAR2 carry their size. ALL_TAB_COLUMNS.data_length holds
    # it in bytes of the national character set (NVARCHAR2(20) is 40 in
    # AL16UTF16); char_length holds the characters, which is what was
    # declared. Without char_length the bytes are divided by the factor.
    if ($lc_dt =~ /^n(?:var)?char2?\z/i) {
      $col{size} = $args{char_length}
        ? $args{char_length}
        : $args{data_length} ? $args{data_length} / $nchar_size_factor : ();
      delete $col{size} unless defined $col{size};
    }
  }
  elsif ($lc_dt =~ /^(?:n?[cb]lob|long(?: raw)?|bfile|date|binary_(?:float|double)|rowid)\z/i) {
    delete $col{size};
  }
  elsif ($lc_dt =~ /^(?:var)?char2?\z/i) {
    # data_length is bytes (80 for VARCHAR2(20 CHAR) in AL32UTF8). A column
    # of character semantics (char_used 'C') is read as "N CHAR", which
    # map_dbio_type_to_oracle writes back as it is; BYTE keeps the plain size.
    $col{size} = ($args{char_used} // '') eq 'C' && $args{char_length}
      ? "$args{char_length} CHAR"
      : $args{data_length};
  }
  elsif ($lc_dt =~ /^(number|decimal)\z/i) {
    $col{data_type} = 'numeric';
    # INTEGER/SMALLINT, what integer is written as, have no precision and a
    # scale of 0; a bare NUMBER has neither. NUMBER(38) and NUMBER(38,0)
    # (precision 38) are numeric like any other NUMBER(p,s).
    if (!defined $args{data_precision} && defined $args{data_scale}
        && $args{data_scale} == 0) {
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
    $col{data_type} = $data_type =~ /local time zone/i ? 'timestamp with local time zone'
                    : $data_type =~ /time zone/i       ? 'timestamp with time zone'
                    :                                    'timestamp';
    $col{size} = $precision unless $precision == 6;
  }
  elsif (my ($year_p) = $lc_dt =~ /^interval year\((\d+)\) to month\z/i) {
    # the dictionary names the precision inside the type: INTERVAL YEAR(3) TO MONTH
    $col{data_type} = 'interval year to month';
    $col{size} = $year_p unless $year_p == 2;
  }
  elsif (my ($day_p, $sec_p) = $lc_dt =~ /^interval day\((\d+)\) to second\((\d+)\)\z/i) {
    $col{data_type} = 'interval day to second';
    $col{size} = [$day_p, $sec_p] unless ($day_p == 2 && $sec_p == 6);
  }
  elsif ($lc_dt eq 'float') {
    # data_length is 22 for every FLOAT; the binary precision is in
    # data_precision, and a FLOAT without one is FLOAT(126), which carries no
    # size here (the dictionary cannot tell the two apart).
    $col{data_type} = 'float';
    $col{size} = $args{data_precision}
      if defined $args{data_precision} && $args{data_precision} != 126;
  }
  elsif ($lc_dt eq 'raw') {
    # data_length of a RAW is its length in bytes, which is what is declared
    $col{size} = $args{data_length} if $args{data_length};
  }

  return \%col;
}


sub map_dbio_type_to_oracle {
  my ($type, %args) = @_;
  $type //= 'varchar2';
  # compared as it means: letter case and blanks (double  precision) are not
  # part of the type; $type itself is what the fallback writes
  (my $lc = lc $type) =~ s/\s+/ /g;
  $lc =~ s/\A | \z//g;

  my $size = $args{size};

  # Render a base type with its optional size, e.g. VARCHAR2(128) or
  # NUMBER(10,2). When no size is given, fall back to $default (which may
  # itself be undef for an unsized base type).
  my $sized = sub {
    my ($base, $default) = @_;
    my $spec = defined $size
      ? (ref $size eq 'ARRAY' ? join(',', grep { defined } @$size) : $size)
      : $default;
    # a length semantics is written the one way: "20 CHAR", "20 BYTE"
    $spec = "$1 \U$2" if defined $spec && $spec =~ /\A\s*(\d+)\s+(char|byte)\s*\z/i;
    return defined $spec && length $spec ? "$base($spec)" : $base;
  };

  # Numeric types
  # INTEGER, not a bare NUMBER: the dictionary reports a bare NUMBER with
  # neither precision nor scale, which is read as numeric, and NUMBER(38) with
  # precision 38, which is numeric(38); INTEGER is precision NULL, scale 0,
  # which only integer is (karr k38).
  return 'INTEGER' if $lc eq 'integer' || $lc eq 'bigint' || $lc eq 'smallint';
  return 'NUMBER(10)' if $lc eq 'serial';
  return 'NUMBER(20)' if $lc eq 'bigserial';

  # Character types
  return $sized->('VARCHAR2', 255) if $lc eq 'varchar' || $lc eq 'varchar2';
  # A national type is of character semantics always; Oracle refuses
  # NCHAR(5 CHAR), so "5 CHAR" is written as 5.
  if ($lc eq 'nvarchar2' || $lc eq 'nvarchar' || $lc eq 'nchar') {
    $size = $1 if defined $size && !ref $size && $size =~ /\A\s*(\d+)\s+CHAR\s*\z/i;
    return $sized->($lc eq 'nchar' ? ('NCHAR', 1) : ('NVARCHAR2', 255));
  }
  return $sized->('CHAR', 1) if $lc eq 'char';
  return 'CLOB' if $lc eq 'text' || $lc eq 'long';

  # Date/time types
  return 'DATE' if $lc eq 'date';
  return $sized->('TIMESTAMP') if $lc eq 'timestamp' || $lc eq 'datetime';
  if ($lc eq 'timestamptz' || $lc eq 'timestamp with time zone') {
    my $ts = $sized->('TIMESTAMP');
    return "$ts WITH TIME ZONE";
  }

  if ($lc eq 'timestamp with local time zone') {
    my $ts = $sized->('TIMESTAMP');
    return "$ts WITH LOCAL TIME ZONE";
  }

  # Binary types
  return 'BLOB' if $lc eq 'bytea' || $lc eq 'blob';
  return 'CLOB' if $lc eq 'clob';

  # Boolean
  return 'NUMBER(1)' if $lc eq 'boolean';

  # Float/double
  return 'BINARY_FLOAT' if $lc eq 'real';
  return 'BINARY_DOUBLE' if $lc eq 'double precision' || $lc eq 'double';
  if ($lc eq 'float') {
    DBIO::Exception->throw(sprintf
      'float takes a binary precision, a whole number from 1 to 126, not %s; refused',
      ref $size ? 'a ' . ref($size) . ' reference' : "'$size'")
      if defined $size && (ref $size || $size !~ /\A[0-9]+\z/ || $size < 1 || $size > 126);
    return $sized->('FLOAT');
  }

  # Numeric/decimal — size may be a scalar precision or [precision, scale]
  return $sized->('NUMBER') if $lc eq 'numeric' || $lc eq 'decimal';

  # Fallback — pass through uppercase, with the size it was given (RAW(16)).
  # An interval carries its precision inside the name, not after it:
  # INTERVAL YEAR(3) TO MONTH, INTERVAL DAY(3) TO SECOND(4).
  if ($lc eq 'interval year to month') {
    return defined $size ? "INTERVAL YEAR($size) TO MONTH" : 'INTERVAL YEAR TO MONTH';
  }
  if ($lc eq 'interval day to second') {
    my ($day, $sec) = ref $size eq 'ARRAY' ? @$size : ($size);
    return 'INTERVAL DAY' . (defined $day ? "($day)" : '')
      . ' TO SECOND' . (defined $sec ? "($sec)" : '');
  }
  return uc $type if $lc =~ /^interval\b/;
  return $sized->(uc $type);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Type - Oracle type mapping utilities

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Consolidated Oracle type mapping logic used by L<DBIO::Oracle::Storage>,
L<DBIO::Oracle::DDL>, L<DBIO::Oracle::Introspect::Columns>, and
L<DBIO::Oracle::Diff::Column>.

=head1 METHODS

=head2 is_lob_type

    $self->is_lob_type($data_type)

Returns true if the given data-type string names a LOB type. Operates on the
plain C<data_type> string carried by a bind's C<sqlt_datatype> (e.g. C<'clob'>,
C<'blob'>, C<'text'>), matching the semantics of the upstream
L<DBIx::Class::Storage::DBI/_is_lob_type>. The leading C<$self> is ignored; it
exists so the function can be called as a method via the storage wrapper.

=head2 is_text_lob_type

    $self->is_text_lob_type($data_type)

Returns true if the data-type string names a text LOB (CLOB/NCLOB), false for a
binary LOB. Mirrors L<DBIx::Class::Storage::DBI/_is_text_lob_type>.

=head2 oracle_lob_bind_attrs

    DBIO::Oracle::Type::oracle_lob_bind_attrs($is_text)

Returns the bind attributes for a LOB bind (ora_type => ORA_BLOB or ORA_CLOB).

=head2 render_default_value

    DBIO::Oracle::Type::render_default_value($default_value)

Renders a column's C<default_value> as the SQL that follows C<DEFAULT>, the one
place that decides it. Used by L<DBIO::Oracle::DDL>,
L<DBIO::Oracle::Diff::Table> and L<DBIO::Oracle::Diff::Column>, and by the
comparison key of the latter, so that what is compared is what is emitted.

=over 4

=item * C<undef> -- C<undef>, there is no default.

=item * a scalar reference -- the text it points to, verbatim: an expression
such as C<SYSDATE> or C<1 + 1>.

=item * a plain value that is a canonical decimal number (C<0>, C<-3>,
C<0.5>, C<12>) -- unquoted, the way L<DBIO::Oracle::Introspect::Columns> reads
a numeric default back. Only the canonical spelling qualifies, so that
rendering never changes the value: C<'007'> and C<'1.50'> stay strings, since a
bare C<007> or C<1.50> would reach a character column as C<7> and C<1.5>.

=item * any other plain value -- a SQL string literal with the apostrophe
doubled: C<it's> becomes C<'it''s'>.

=back

=head2 normalize_type

    DBIO::Oracle::Type::normalize_type($type)

Normalizes an Oracle data type string for comparison (uppercase, collapse
whitespace).

=head2 map_dbd_type_to_dbio

    DBIO::Oracle::Type::map_dbd_type_to_dbio($data_type, %args)

Maps an Oracle data type string (from ALL_TAB_COLUMNS) to a DBIO canonical
type name. %args may include C<data_length>, C<char_length>, C<char_used>, C<data_precision>,
C<data_scale> and C<nchar_size_factor> for UTF-16 correction.

Returns a hashref with C<data_type> and, where applicable, C<size>.

An Oracle C<DATE> is C<date>, C<BINARY_FLOAT> and C<BINARY_DOUBLE> are
C<binary_float> and C<binary_double> (size dropped): they are not mapped to
C<datetime>, C<real> and C<double precision>, since a C<DATE> read as
C<datetime> would be written as C<TIMESTAMP> and modified on every run.
C<FLOAT> is C<float> with its binary precision (C<data_precision>) as the
size, C<FLOAT(126)> and a C<FLOAT> without precision, which the dictionary
cannot tell apart, being C<float> without a size. The sizes of C<VARCHAR2>,
C<NVARCHAR2>, C<NCHAR> and C<TIMESTAMP(n)> are kept (C<TIMESTAMP(6)>, the
default, carries none); C<TIMESTAMP(n) WITH LOCAL TIME ZONE> is its own type,
C<timestamp with local time zone>, with the same size rule, and is written
back as such; C<NUMBER> without precision is C<numeric>. A C<VARCHAR2> or
C<CHAR> declared with character semantics (C<char_used> C<'C'>) has the size
C<"20 CHAR">, a string that L</map_dbio_type_to_oracle> writes as
C<VARCHAR2(20 CHAR)>; a byte one keeps the plain number.
C<INTEGER>/C<SMALLINT> (the dictionary holds a scale of 0 and no precision)
are C<integer>, and only those: C<NUMBER(38)> and C<NUMBER(38,0)> are
C<numeric> with the size C<[38, 0]>.

=head2 map_dbio_type_to_oracle

    DBIO::Oracle::Type::map_dbio_type_to_oracle($dbio_type, %args)

Maps a DBIO canonical type name to an Oracle DDL type string.
%args may include C<size> for VARCHAR2(n), NVARCHAR2(n), NCHAR(n),
TIMESTAMP(n) and NUMBER(p,s). A size is written as given, so C<'20 CHAR'>
gives C<VARCHAR2(20 CHAR)>. C<float> is C<FLOAT> or C<FLOAT(n)> (C<FLOAT>
being C<FLOAT(126)>); C<real> is C<BINARY_FLOAT>, C<double precision> and
C<double> (the portable base type, which Oracle has not under that name) are
C<BINARY_DOUBLE>. A C<float> size is a whole number from 1 to 126; anything
else throws. C<NCHAR> and C<NVARCHAR2> are of character semantics always, so
C<'5 CHAR'> is written as C<NCHAR(5)>. A size of another type is written as
given, C<RAW(16)> included. C<nvarchar> is C<NVARCHAR2>. An C<interval year to
month> takes its year precision as the size (C<INTERVAL YEAR(3) TO MONTH>), an
C<interval day to second> C<[day, second]> (C<INTERVAL DAY(3) TO SECOND(4)>). A
scale of C<undef> in a numeric size is left out (C<NUMBER(10)>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
