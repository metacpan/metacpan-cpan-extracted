package DBIO::MySQL::DefaultValue;
# ABSTRACT: MySQL/MariaDB DEFAULT values for generated DDL, written and read

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';

our @EXPORT_OK = qw(default_sql catalog_default catalog_on_update on_update_sql);



# The spellings of "now" both servers take as a column default without
# parentheses (and as ON UPDATE).
my $NOW = qr/\A(?:current_timestamp|now|localtime|localtimestamp)(?:\(\s*\d*\s*\))?\z/i;

sub default_sql {
  my ($value, $is_expression) = @_;

  return $$value if ref $value eq 'SCALAR';

  if ($is_expression) {
    return $value =~ $NOW ? $value : "($value)";
  }

  (my $lit = $value) =~ s/\\/\\\\/g;
  $lit =~ s/'/''/g;
  $lit =~ s/\0/\\0/g;
  return "'$lit'";
}


sub catalog_default {
  my (%a) = @_;
  my $raw = $a{raw};
  return (undef, 0) unless defined $raw;

  if ($a{mariadb_expression}) {
    if ($raw =~ /\A'(.*)'\z/s) {
      my $lit = $1;
      my %esc = (n => "\n", r => "\r", t => "\t", 0 => "\0", Z => "\x1a", b => "\b");
      $lit =~ s/''/'/g;
      $lit =~ s/\\(.)/exists $esc{$1} ? $esc{$1} : $1/gse;
      return ($lit, 0);
    }
    return ($raw, 0) if $raw =~ /\A[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\z/;
    return ($raw, 1);
  }

  if (($a{extra} // '') =~ /\bDEFAULT_GENERATED\b/i) {
    (my $expr = $raw) =~ s/\\'/'/g;
    return ($expr, 1);
  }

  return ($raw, 1)
    if $raw =~ $NOW && ($a{data_type} // '') =~ /\A(?:timestamp|datetime)\z/i;

  return ($raw, 0);
}


sub catalog_on_update {
  my ($extra) = @_;
  return undef unless defined $extra && $extra =~ /\bon\s+update\s+(\w+(?:\(\s*\d*\s*\))?)/i;
  (my $expr = uc $1) =~ s/\s+//g;
  $expr =~ s/\(\)\z//;
  return $expr;
}


sub on_update_sql {
  my ($on_update) = @_;
  return defined $on_update && length $on_update ? " ON UPDATE $on_update" : '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::DefaultValue - MySQL/MariaDB DEFAULT values for generated DDL, written and read

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Single source of truth for what stands behind C<DEFAULT> in a statement this
driver generates, and for what a column's default is once the catalog has
reported it. The install DDL (L<DBIO::MySQL::DDL>), the C<CREATE TABLE> of a
diff (L<DBIO::MySQL::Diff::Table>) and its C<ADD> / C<MODIFY COLUMN>
(L<DBIO::MySQL::Diff::Column>) write it through L</default_sql>;
L<DBIO::MySQL::Introspect::Columns> reads it through L</catalog_default>.

A default is a I<literal> (a value, written as a string literal) or an
I<expression> (C<CURRENT_TIMESTAMP>, C<uuid()>, written as SQL). The model
carries the difference as two keys of a column: C<default_value>, the text, and
C<default_is_expression>, C<0> or C<1>. A scalar reference as C<default_value>
(a schema's own C<\'CURRENT_TIMESTAMP'>) is an expression written as it is.

C<ON UPDATE CURRENT_TIMESTAMP> is not a default but stands beside it, and the
model carries it as a third key, C<on_update> (L</catalog_on_update>,
L</on_update_sql>). A schema declares it with no key of its own, in the scalar
reference: C<< default_value => \'CURRENT_TIMESTAMP ON UPDATE
CURRENT_TIMESTAMP' >>.

=head1 METHODS

=head2 default_sql

    my $sql = default_sql($value, $is_expression);   # 'it''s', CURRENT_TIMESTAMP, (uuid())

The text after C<DEFAULT> for a defined C<$value>.

=over 4

=item * A scalar reference is written as it stands.

=item * A literal becomes a string literal: the apostrophe is doubled, and so
is the backslash, because it is an escape in the default C<sql_mode> of both
servers (measured on MySQL 8.0.30 and MariaDB 11.8.9: C<'a\\b'> is the value
C<a\b>). A NUL byte is written C<\0>. Under C<NO_BACKSLASH_ESCAPES> a doubled
backslash would stay two; the driver does not set that mode.

=item * An expression is written bare when it is C<CURRENT_TIMESTAMP> or one of
its spellings (C<NOW()>, C<LOCALTIME>, ... with or without a precision), the
only expressions the servers take without parentheses; any other is put in
parentheses (C<DEFAULT (uuid())>), which both servers accept from MySQL 8.0.13
and MariaDB 10.2.1.

=back

=head2 catalog_default

    my ($value, $is_expression) = catalog_default(
      raw => $column_default, extra => $extra, data_type => $type, mariadb_expression => 1);

What the server's C<information_schema.columns.column_default> means, as the
pair the model carries. The two servers fill it in differently (measured):

=over 4

=item * MySQL reports a literal as the value itself (C<it's>, C<a\b>) and an
expression as its text; the column's C<EXTRA> says which: it contains
C<DEFAULT_GENERATED> for an expression (C<CURRENT_TIMESTAMP>, C<uuid()>,
C<concat(_utf8mb4\'a\',...)>, with a quote it escaped in the report).
Before 8.0.13 only C<CURRENT_TIMESTAMP> of a C<timestamp> / C<datetime> column
is an expression, and C<EXTRA> does not say so.

=item * MariaDB from 10.2.7 (C<mariadb_expression>) reports an expression
throughout: a string literal in quotes with the apostrophe doubled and the
backslash and control characters escaped (C<'it''s'>, C<'a\\b'>, C<'a\nb'>), a
number bare (C<5>, C<1.50>), anything else is an expression
(C<current_timestamp()>, C<concat('a','b')>). The literal is returned
unquoted and unescaped, so it is the value, as MySQL reports it.

=back

C<undef> stays C<undef>.

=head2 catalog_on_update

    my $on_update = catalog_on_update($extra);   # 'CURRENT_TIMESTAMP', 'CURRENT_TIMESTAMP(6)', undef

The C<ON UPDATE> of a column, from its C<EXTRA>. Both servers
carry it there, in their own spelling (measured on MySQL 8.0.30 and MariaDB
11.8.9): MySQL C<DEFAULT_GENERATED on update CURRENT_TIMESTAMP(6)>, MariaDB
C<on update current_timestamp(6)>, and C<current_timestamp()> where MySQL has
C<CURRENT_TIMESTAMP>. The answer is one spelling for both: upper case, the
precision kept, the C<()> of a plain C<current_timestamp()> taken off.
C<undef> for a column without C<ON UPDATE>.

=head2 on_update_sql

    my $sql = on_update_sql($on_update);   # ' ON UPDATE CURRENT_TIMESTAMP', ''

The clause a statement writes for the C<on_update> of a column model, with its
leading space, or the empty string for none. A C<MODIFY COLUMN> that leaves it
out takes the attribute off the column.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
