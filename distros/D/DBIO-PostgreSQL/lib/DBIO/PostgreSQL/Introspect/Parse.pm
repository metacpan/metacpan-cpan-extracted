package DBIO::PostgreSQL::Introspect::Parse;
# ABSTRACT: Pure parsers for raw PostgreSQL metadata strings

use strict;
use warnings;

our $VERSION = '0.900004';



sub include_columns {
  my ($class, $definition) = @_;
  return [] unless defined $definition;
  if ($definition =~ /\bINCLUDE\s*\(([^)]+)\)/i) {
    my $cols = $1;
    return [ map { s/^\s+|\s+$//g; s/^"|"$//g; $_ } split /,/, $cols ];
  }
  return [];
}


sub storage_params {
  my ($class, $reloptions) = @_;
  return {} unless defined $reloptions;
  my $raw = $reloptions;
  $raw =~ s/^\{|\}$//g if !ref $raw;
  my @items = ref $raw ? @$raw : split /,/, $raw;
  my %params;
  for my $item (@items) {
    $item =~ s/^\s+|\s+$//g;
    if ($item =~ /^(.+?)=(.+)$/) {
      $params{$1} = $2;
    }
  }
  return \%params;
}


sub column_opclasses {
  my ($class, $definition) = @_;
  return {} unless defined $definition;

  my $list = _key_column_list($definition);
  return {} unless defined $list;

  my %opclasses;
  for my $item (_split_top_level($list)) {
    $item =~ s/^\s+|\s+$//g;
    next unless length $item;
    next if $item =~ /^\(/;    # expression entry, not a plain column

    my ($column, $rest);
    if ($item =~ /^"((?:[^"]|"")*)"\s*(.*)$/s) {
      ($column, $rest) = ($1, $2);
      $column =~ s/""/"/g;
    }
    elsif ($item =~ /^([^\W\d][\w\$]*)\s*(.*)$/s) {
      ($column, $rest) = ($1, $2);
    }
    else {
      next;
    }

    # A COLLATE clause sits between the column and its operator class.
    $rest =~ s/^COLLATE\s+(?:"(?:[^"]|"")*"|[^\W\d][\w\$.]*)\s*//i;

    next unless $rest =~ /^([^\W\d][\w\$]*(?:\.[^\W\d][\w\$]*)?)\s*(\([^)]*\))?/;
    my ($name, $params) = ($1, $2);
    next if $name =~ /^(?:ASC|DESC|NULLS)\z/i;

    $opclasses{$column} = $name . (defined $params ? $params : '');
  }

  return \%opclasses;
}

# The key-column list of an index definition: everything between the '('
# that follows "USING <access_method>" and its matching ')'. Returns undef
# when there is no such balanced list. Scanned character-wise rather than
# with a regex because expression entries nest parentheses and may contain
# commas -- "USING btree (lower((a || ','::text)))".
sub _key_column_list {
  my ($definition) = @_;
  return undef
    unless $definition =~ /\bUSING\s+(?:"(?:[^"]|"")*"|[^\W\d][\w\$]*)\s*\(/gi;

  my $depth    = 1;
  my $in_quote = 0;
  my $out      = '';
  for my $char (split //, substr($definition, pos $definition)) {
    if ($in_quote) {
      $out .= $char;
      $in_quote = 0 if $char eq '"';
      next;
    }
    if ($char eq '"') { $in_quote = 1 }
    elsif ($char eq '(') { $depth++ }
    elsif ($char eq ')') {
      $depth--;
      last if $depth == 0;
    }
    $out .= $char;
  }

  return $depth == 0 ? $out : undef;
}

# Split on the commas that separate index key entries, i.e. those outside
# any nested parentheses and outside a quoted identifier.
sub _split_top_level {
  my ($text) = @_;
  my @parts;
  my $depth    = 0;
  my $in_quote = 0;
  my $current  = '';
  for my $char (split //, $text) {
    if ($in_quote) {
      $current .= $char;
      $in_quote = 0 if $char eq '"';
      next;
    }
    if ($char eq '"') { $in_quote = 1 }
    elsif ($char eq '(') { $depth++ }
    elsif ($char eq ')') { $depth-- }
    elsif ($char eq ',' && $depth == 0) {
      push @parts, $current;
      $current = '';
      next;
    }
    $current .= $char;
  }
  push @parts, $current if length $current;
  return @parts;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Parse - Pure parsers for raw PostgreSQL metadata strings

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Leaf module with pure-data parsers that turn raw C<pg_catalog> strings
(typically produced by C<pg_get_indexdef> and C<reloptions>) into the
canonical Perl structures consumed by L<DBIO::Generate>. None of these
subs talk to the database or hold state; they are class methods that
take scalars / arrayrefs and return arrayrefs / hashrefs.

L<DBIO::PostgreSQL::Introspect::Indexes> no longer reads the INCLUDE columns and
the operator classes of an index through C</include_columns> and
C</column_opclasses>: it reads them from the catalog (C<pg_index.indnkeyatts>,
C<indclass>, C<indoption>), which keeps a sort order and an operator class in a
quoted schema that these two lose. They remain as parsers of a definition
string for whoever has only the text.

The parsers are:

=over 4

=item * L</include_columns> -- extracts the C<INCLUDE (col1, col2, ...)>
clause from an index definition

=item * L</storage_params> -- decodes a C<reloptions> array / string of
C<key=value> pairs into a hashref

=item * L</column_opclasses> -- extracts the per-column operator classes
from the key-column list of an index definition

=back

=head2 include_columns

    my $cols = DBIO::PostgreSQL::Introspect::Parse->include_columns($def);

Returns an ArrayRef of column names listed in the C<INCLUDE (col, col)>
clause of the index definition C<$def>. Returns C<[]> when the clause
is missing or the definition is C<undef>. Column names are stripped of
surrounding whitespace and double quotes.

=head2 storage_params

    my $params = DBIO::PostgreSQL::Introspect::Parse->storage_params($reloptions);

Decodes C<reloptions> (C<pg_class.reloptions>) into a hashref. Accepts
either a string of the form C<{key=value, key=value}> or an ArrayRef
of C<key=value> strings. Returns C<{}> for empty / undef input.

=head2 column_opclasses

    my $ops = DBIO::PostgreSQL::Introspect::Parse->column_opclasses($def);

Returns a HashRef of column name to operator class name for every plain
column in the key-column list of the index definition C<$def> that carries
a non-default operator class. C<pg_get_indexdef> only prints the operator
class when it is B<not> the access method's default for the column type, so
an empty hashref means "every column uses its default opclass" -- which is
also what is returned for an undef / unparseable definition.

    CREATE INDEX i ON t USING hnsw (embedding vector_cosine_ops)
      -> { embedding => 'vector_cosine_ops' }

Sort options (C<ASC>, C<DESC>, C<NULLS FIRST/LAST>) and a C<COLLATE> clause
are recognised and skipped, so C<(name COLLATE "C" text_pattern_ops DESC)>
yields C<< { name =E<gt> 'text_pattern_ops' } >>. Operator class parameters
(PostgreSQL 13+, e.g. C<tsvector_ops(siglen=32)>) are kept with the name.
Expression entries are ignored: their operator class cannot be attached to a
column name, and it stays in the definition string that
L<DBIO::PostgreSQL::Diff::Index> compares.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
