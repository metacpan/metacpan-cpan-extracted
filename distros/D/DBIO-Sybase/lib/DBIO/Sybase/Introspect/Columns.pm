package DBIO::Sybase::Introspect::Columns;
# ABSTRACT: Introspect Sybase ASE columns

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Sybase::DDL ();



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %columns;

  my $rows = $dbh->selectall_arrayref(q{
    SELECT o.name AS table_name, c.name AS column_name, c.colid,
           t.name AS type_name, c.length, c.prec, c.scale,
           c.status, c.cdefault, @@ncharsize AS ncharsize
    FROM syscolumns c
    JOIN sysobjects o ON o.id = c.id
    JOIN sysusers   u ON u.uid = o.uid
    JOIN systypes   t ON t.usertype = c.usertype
    WHERE o.type IN ('U', 'V')
      AND u.name = ?
    ORDER BY o.name, c.colid
  }, { Slice => {} }, $schema);

  for my $row (@$rows) {
    next unless exists $tables->{ $row->{table_name} };
    my $status = $row->{status} // 0;
    my $col = {
      column_name       => $row->{column_name},
      data_type         => $row->{type_name},
      not_null          => ($status & 8)   ? 0 : 1,
      default_value     => undef,
      is_pk             => 0,
      pk_position       => 0,
      is_auto_increment => ($status & 128) ? 1 : 0,
    };
    my $size = _size($row);
    $col->{size} = $size if defined $size;
    push @{ $columns{ $row->{table_name} } }, $col;
  }

  _mark_defaults($dbh, $schema, \%columns);

  return \%columns;
}

# DBIO size convention from syscolumns length/prec/scale.
sub _size {
  my ($row) = @_;
  my $type = lc($row->{type_name} // '');
  if ($type eq 'numeric' || $type eq 'decimal') {
    return defined $row->{prec} ? [ $row->{prec}, $row->{scale} // 0 ] : undef;
  }
  if ($type =~ /char\z/) {
    return undef unless defined $row->{length};
    # length is bytes, the declared size characters. unichar/univarchar store
    # UTF-16, two bytes each. nchar/nvarchar reserve @@ncharsize bytes per
    # character -- the maximum width of the server's default character set:
    # 1 under iso_1, 3 under utf8 (karr k57) -- so nvarchar(10) is length 30
    # on a utf8 server and read back there as 30 without the division.
    return int($row->{length} / 2) if $type =~ /\Auni/;
    return int($row->{length} / ($row->{ncharsize} || 1)) if $type =~ /\An/;
    return $row->{length};
  }
  # binary(n) / varbinary(n): length is the n bytes, no character width (karr k93).
  return $row->{length} if ($type eq 'binary' || $type eq 'varbinary') && defined $row->{length};
  return undef;
}

# Default text lives in syscomments under the id syscolumns.cdefault points at,
# split over several rows when long (colid2/colid order).
sub _mark_defaults {
  my ($dbh, $schema, $columns) = @_;

  my $rows = $dbh->selectall_arrayref(q{
    SELECT o.name AS table_name, c.name AS column_name, m.text
    FROM syscolumns  c
    JOIN sysobjects  o ON o.id = c.id
    JOIN sysusers    u ON u.uid = o.uid
    JOIN syscomments m ON m.id = c.cdefault
    WHERE c.cdefault <> 0
      AND o.type = 'U'
      AND u.name = ?
    ORDER BY o.name, c.colid, m.colid2, m.colid
  }, { Slice => {} }, $schema);

  my %text;
  for my $row (@$rows) {
    $text{ $row->{table_name} }{ $row->{column_name} } .= $row->{text} // '';
  }

  for my $table (keys %text) {
    my $list = $columns->{$table} or next;
    for my $col (@$list) {
      my $t = $text{$table}{ $col->{column_name} };
      $col->{default_value} = _normalize_default($t, $col->{data_type}) if defined $t;
    }
  }
}

# Inverse of DBIO::Sybase::DDL::sybase_default_clause, which renders a literal
# by the column's type (karr k55): quoted on a character column, bare on a
# numeric one. So the type decides here too. A bare number on a numeric column
# is the literal it was written as. A QUOTED text on a numeric column is not --
# it is what the pre-k55 DDL wrote, a VARCHAR constant that fails every
# defaulted INSERT -- and stays the SQL it is, so the diff sees it differ from
# the desired literal and replaces it instead of reading both as '0'.
sub _normalize_default {
  my ($text, $data_type) = @_;
  $text =~ s/\A\s*DEFAULT\s+//i
    or $text =~ s/\A\s*create\s+default\s+\S+\s+as\s+//i;
  $text =~ s/\s+\z//;
  return undef unless length $text;
  my $numeric = DBIO::Sybase::DDL::_is_numeric_type($data_type);
  return $text if $numeric && DBIO::Sybase::DDL::_is_numeric_literal($text);
  if (!$numeric && $text =~ /\A'((?:[^']|'')*)'\z/s) {
    (my $lit = $1) =~ s/''/'/g;
    return $lit;
  }
  return \$text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Introspect::Columns - Introspect Sybase ASE columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches column metadata from the ASE system catalog: C<syscolumns> joined to
C<sysobjects> / C<sysusers> (owner) and C<systypes>, plus C<syscomments> for
the text of column defaults. SAP ASE has no C<INFORMATION_SCHEMA> views.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::Sybase::Introspect::Columns->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Sybase::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs in C<colid> order with keys:
C<column_name>, C<data_type>, C<not_null>, C<default_value>,
C<is_pk>, C<pk_position>, C<is_auto_increment>, and C<size> where it applies.

The values are read so they re-render through L<DBIO::Sybase::DDL> exactly as
the DDL that created the column wrote them -- both sides of
L<DBIO::Sybase::Deploy>'s test-deploy-and-compare are introspected, so any
drift between catalog value and rendering is a phantom diff:

=over 4

=item * C<data_type> is the C<systypes> name found through
C<syscolumns.usertype> -- the B<declared> type (C<int>, C<bigint>,
C<numeric>). C<syscolumns.type> would report the nullable storage variant
(C<intn>, C<numericn>) for every nullable column.

=item * C<not_null> is C<status & 8> clear; C<is_auto_increment> is
C<status & 0x80>.

=item * C<size> is C<syscolumns.length> for character types -- halved for the
UTF-16 C<unichar> / C<univarchar>, and divided by C<@@ncharsize> for C<nchar> /
C<nvarchar>, whose length is the declared size times the byte width of the
server's default character set (1 under C<iso_1>, 3 under C<utf8>) -- the
byte length for C<binary> / C<varbinary>, C<[prec, scale]> for C<numeric> /
C<decimal>, and absent otherwise (a C<text>/C<image> column's length of 16 is
the page pointer, not a width).

=item * C<default_value> comes from the C<syscomments> text behind
C<syscolumns.cdefault> (C<DEFAULT  'x'>, or C<create default d as ...> for a
bound default). A single-quoted literal becomes its bare value with C<''>
unescaped -- L<DBIO::Sybase::DDL/sybase_default_clause> quotes it again -- and
anything else (C<getdate()>) becomes a SCALAR ref, which that function emits
verbatim. The column type decides like it does there: on a numeric column an
unquoted number (C<DEFAULT 0>, C<DEFAULT -1.5>) is the bare literal, and a
B<quoted> text (C<DEFAULT '0'>, as other DDL writers emit it, and a C<VARCHAR>
constant every defaulted C<INSERT> trips over) is a SCALAR ref carrying the
quotes, so a diff against the desired C<0> sees the difference and replaces
it.

=back

C<is_pk> / C<pk_position> are left at C<0> here: the primary key is the
PK-constraint index (C<sysindexes.status & 2048>), which
L<DBIO::Sybase::Introspect::Indexes> reads, and L<DBIO::Sybase::Introspect>
marks the columns from it.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
