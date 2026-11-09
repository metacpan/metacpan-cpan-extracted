package DBIO::DB2::Introspect::Columns;
# ABSTRACT: Introspect DB2 columns

use strict;
use warnings;

our $VERSION = '0.900004';



# Types Db2 declares without a length: the catalog's LENGTH is a storage length
# (SMALLINT 2, INTEGER 4, DATE 4, ...) and no size is normalized from it.
my %DECLARED_WITHOUT_LENGTH = map { $_ => 1 } (
  'SMALLINT', 'INTEGER', 'BIGINT', 'REAL', 'DOUBLE', 'DATE', 'TIME', 'XML',
  'BOOLEAN', 'LONG VARCHAR', 'LONG VARGRAPHIC',
);

my %DATA_TYPE = (
  'CHARACTER' => 'char',
  'DOUBLE'    => 'double precision',
);

sub _normalized_type {
  my ($typename) = @_;
  return $DATA_TYPE{$typename} // lc $typename;
}

sub _normalized_size {
  my ($typename, $length, $scale) = @_;
  return undef if $DECLARED_WITHOUT_LENGTH{$typename};
  return undef unless defined $length;
  return $scale // 0 if $typename eq 'TIMESTAMP';
  return ($length == 8 ? 16 : $length == 16 ? 34 : $length) if $typename eq 'DECFLOAT';
  return [ $length + 0, ($scale // 0) + 0 ] if $typename eq 'DECIMAL';
  return $length + 0;
}

# The catalog's DEFAULT is SQL text: a string literal becomes the string, a
# number stays its text, anything else is an expression and a SCALAR reference.
sub _normalized_default {
  my ($text) = @_;
  return undef unless defined $text;
  (my $t = $text) =~ s/\A\s+|\s+\z//g;
  return undef if $t eq '' || uc($t) eq 'NULL';
  if ($t =~ /\A'((?:[^']|'')*)'\z/s) {
    (my $v = $1) =~ s/''/'/g;
    return $v;
  }
  return $t if $t =~ /\A[+-]?\d+(?:\.\d+)?\z/;
  return \$t;
}

# The catalog keeps the text of a DEFAULT as it was written. For a BOOLEAN a quoted
# number ('1') and the bare number (1) are one default, and install_ddl writes a
# class value of digits bare, so the catalog form is read as the number: the
# column made by hand with DEFAULT '1' and the one made from its class compare
# equal (karr k55). Other defaults, and other types, stay as the catalog has them.
sub _catalog_default {
  my ($typename, $text) = @_;
  return $text unless defined $text && $typename eq 'BOOLEAN';
  (my $t = $text) =~ s/\A\s+|\s+\z//g;
  return $1 if $t =~ /\A'([+-]?\d+(?:\.\d+)?)'\z/;
  return $text;
}

sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys
  my %columns;

  # Pull all columns for the schema in one go.
  my $col_sth = $dbh->prepare(q{
    SELECT colname, tabname, colno, typename, nulls, default,
           length, scale, identity
    FROM syscat.columns
    WHERE tabschema = ?
    ORDER BY tabname, colno
  });
  $col_sth->execute($schema);

  while (my $row = $col_sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{tabname} };
    my $type = $row->{typename};
    my $size = $row->{length};
    if ($type eq 'TIMESTAMP') {
      # The one type whose LENGTH is not what its declaration takes: LENGTH is
      # the storage length (7 to 13) and SCALE the fractional-seconds precision
      # (0 to 12), and TIMESTAMP(p) takes the precision alone. "10,6" made the
      # diff write TIMESTAMP(10,6) (SQL0104N); the bare length 7 of a
      # TIMESTAMP(0) was accepted and gave a TIMESTAMP(7) (karr k41).
      $size = $row->{scale};
    }
    elsif ($type eq 'DECFLOAT') {
      # LENGTH is the storage length, 8 or 16 bytes, of DECFLOAT(16) and
      # DECFLOAT(34); the declaration takes the digits. Carried as the digits,
      # size is what a result class writes and what the diff renders back
      # (karr k45).
      $size = $size == 8 ? 16 : $size == 16 ? 34 : $size;
    }
    elsif (defined $row->{scale} && $row->{scale} > 0) {
      $size .= ",$row->{scale}";
    }
    my %col = (
      column_name   => $row->{colname},
      data_type     => _normalized_type($type),
      not_null      => (uc($row->{nulls} // 'Y') eq 'N') ? 1 : 0,
      default_value => _normalized_default($row->{default}),
      is_pk         => 0,
      pk_position   => 0,
      # What the catalog holds, for the diff (ADR 0013).
      catalog_type    => $type,
      catalog_size    => $size // undef,
      catalog_default => _catalog_default($type, $row->{default}),
    );
    my $norm_size = _normalized_size($type, $row->{length}, $row->{scale});
    $col{size} = $norm_size if defined $norm_size;
    # GENERATED ... AS IDENTITY -> syscat.columns.identity = 'Y'
    $col{is_auto_increment} = 1 if lc($row->{identity} // 'N') eq 'y';
    push @{ $columns{ $row->{tabname} } }, \%col;
  }

  # Primary-key membership.
  my $pk_sth = $dbh->prepare(q{
    SELECT kcu.tabname, kcu.colname, kcu.colseq
    FROM syscat.keycoluse kcu
    JOIN syscat.tabconst tc
      ON kcu.constname = tc.constname
        AND kcu.tabschema = tc.tabschema
        AND kcu.tabname = tc.tabname
    WHERE tc.tabschema = ?
      AND tc.type = 'P'
    ORDER BY kcu.tabname, kcu.colseq
  });
  $pk_sth->execute($schema);

  while (my $row = $pk_sth->fetchrow_hashref) {
    my $list = $columns{ $row->{tabname} } or next;
    for my $col (@$list) {
      if ($col->{column_name} eq $row->{colname}) {
        $col->{is_pk}       = 1;
        $col->{pk_position} = $row->{colseq} || 1;
        last;
      }
    }
  }

  return \%columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Introspect::Columns - Introspect DB2 columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches column metadata via C<SYSCAT.COLUMNS>. Primary-key membership
is determined via C<SYSCAT.KEYCOLUSE> joined with C<SYSCAT.TABCONST>.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::DB2::Introspect::Columns->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::DB2::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs in C<COLNO> order.

B<The normalized fields> are the L<DBIO::Introspect::Base> contract that
L<DBIO::Generate> reads through C<table_columns_info> (ADR 0013):
C<column_name>, C<data_type>, C<size>, C<not_null>, C<default_value>, C<is_pk>,
C<pk_position>, and C<is_auto_increment> (set to 1 only for
C<GENERATED ... AS IDENTITY> columns).

=over 4

=item * C<data_type> is the lower-case type name a result class writes:
C<char> for C<CHARACTER>, C<double precision> for C<DOUBLE>, otherwise
C<TYPENAME> lower-cased (C<varchar>, C<integer>, C<decfloat>, C<timestamp>).

=item * C<size> is the declared length: a number for C<CHAR>, C<VARCHAR>,
C<BINARY>, C<VARBINARY>, C<GRAPHIC>, C<VARGRAPHIC>, C<CLOB>, C<BLOB>,
C<DBCLOB>; C<[precision, scale]> for C<DECIMAL>; the fractional-seconds
precision for C<TIMESTAMP>; the digits (16 or 34) for C<DECFLOAT>. B<Absent> for
a type Db2 declares without one (C<SMALLINT>, C<INTEGER>, C<BIGINT>, C<REAL>,
C<DOUBLE>, C<DATE>, C<TIME>, C<XML>, C<BOOLEAN>, C<LONG VARCHAR>), whose
C<LENGTH> in the catalog is its storage length.

=item * C<default_value> is the value: a string without its quotes
(C<'it''s'> is C<it's>), a number as its text, and an expression
(C<CURRENT TIMESTAMP>, C<USER>, C<CURRENT DATE>, ...) as a SCALAR reference
(C<\'CURRENT TIMESTAMP'>), the form L<DBIO::DB2::DDL> writes bare. No default,
and an explicit C<DEFAULT NULL>, are C<undef>.

=back

B<The catalog fields> are internal, for L<DBIO::DB2::Diff> and its operations,
which render and compare what the catalog holds. They are not part of any
contract and no other consumer reads them:

=over 4

=item * C<catalog_type> is C<TYPENAME> (C<CHARACTER>, C<DOUBLE>).

=item * C<catalog_size> is C<LENGTH> -- the storage length for a type declared
without one -- with C<SCALE> after a comma when that is above zero (C<10,2>).
C<TIMESTAMP> is the exception, its value is C<SCALE> alone; C<DECFLOAT>
carries its digits, C<LENGTH> 8 or 16 as 16 or 34.

=item * C<catalog_default> is C<DEFAULT>, the SQL text of the default
(C<'new'> with its quotes, C<'it''s'>, C<0>, C<CURRENT TIMESTAMP>). One
exception, for a C<BOOLEAN>: a quoted number (C<'1'>) is read as the number
(C<1>), the form L<DBIO::DB2::DDL> writes for a class value of digits, so the
column made by hand with C<DEFAULT '1'> and the one made from its class do not
differ; C<TRUE>, C<FALSE> and a quoted word (C<'true'>) stay.

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
