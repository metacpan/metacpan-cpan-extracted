# ABSTRACT: Shared SQL utility functions for DBIO

use strict;
use warnings;

package DBIO::SQL::Util;

use Exporter 'import';

our @EXPORT_OK = qw(_quote_ident _split_statements);


# Quote a SQL identifier.
# Unquoted identifiers must match /^[a-z_][a-z0-9_]*$/i (case-insensitive).
# Embedded double-quotes in quoted identifiers are escaped as "".
sub _quote_ident {
  my ($name) = @_;

  # Simple unquoted identifier: starts with letter or underscore,
  # followed by letters, digits, or underscores (case-insensitive)
  return $name if $name =~ /^[a-z_][a-z0-9_]*$/i;

  # Double-quote the identifier, escaping embedded double-quotes as ""
  $name =~ s/"/""/g;
  return qq{"$name"};
}

# Split SQL on semicolons, handling $$ dollar-quoting.
# Trims whitespace, discards blank statements.
sub _split_statements {
  my ($sql) = @_;

  my @stmts;
  my $in_dollar = 0;
  my $current = '';
  my $len = length $sql;
  my $i = 0;

  while ($i < $len) {
    my $ch = substr $sql, $i, 1;

    # Track $$ dollar quoting
    if ($ch eq '$') {
      my $j = $i + 1;
      while ($j < $len && substr($sql, $j, 1) ne '$') { $j++ }
      if ($j < $len && substr($sql, $j + 1, 1) eq '$') {
        # This is $$ - toggle dollar quoting state
        $in_dollar = !$in_dollar;
        $current .= '$$';
        $i = $j + 2;
        next;
      } elsif ($j < $len) {
        # Tagged dollar quote: $tag$ ... $tag$
        my $tag = substr $sql, $i + 1, $j - $i - 1;
        my $close_tag = '$' . $tag . '$';
        my $close_pos = index $sql, $close_tag, $j + 1;
        if ($close_pos >= 0) {
          my $dollar_content = substr $sql, $i, $close_pos - $i + length($close_tag);
          $current .= $dollar_content;
          $i = $close_pos + length($close_tag);
          next;
        }
      }
    }

    # Split on semicolons outside dollar quotes
    if ($ch eq ';' && !$in_dollar) {
      $current =~ s/^\s+|\s+$//g;
      push @stmts, $current if $current =~ /\S/;
      $current = '';
      $i++;
      next;
    }

    $current .= $ch;
    $i++;
  }

  # Handle remaining content (last statement without trailing semicolon)
  $current =~ s/^\s+|\s+$//g;
  push @stmts, $current if $current =~ /\S/;

  return @stmts;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQL::Util - Shared SQL utility functions for DBIO

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
