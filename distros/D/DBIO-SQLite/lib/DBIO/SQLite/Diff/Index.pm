package DBIO::SQLite::Diff::Index;
# ABSTRACT: Diff operations for SQLite indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_fields);
use DBIO::SQLite::Util qw(quote_identifier sql_tokens token_identifier);
use namespace::clean;


__PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info replaced/);


# The CREATE INDEX statement of an index in the form two of them are compared
# in -- see "What counts as a changed index". The tokens of the statement,
# without whitespace and comments, joined by one space; a name at a place where
# the grammar has nothing but a name is written in the driver's own quoting,
# whichever quoting it came in.
#
#   CREATE [UNIQUE] INDEX name ON table ( entry, ... ) [WHERE ...]
sub _comparable_sql {
  my ($sql) = @_;
  my @tokens = grep { $_->[0] ne 'skip' } sql_tokens($sql);
  my $plain  = join ' ', map { $_->[1] } @tokens;

  # A token that can be a name: a word, or quoted in anything but apostrophes.
  my $name = sub {
    my ($token) = @_;
    return unless $token
      && ($token->[0] eq 'word' || ($token->[0] eq 'quoted' && $token->[1] !~ /\A'/));
    return quote_identifier(token_identifier(@$token));
  };
  my $keyword = sub {
    my ($token, $word) = @_;
    return $token && $token->[0] eq 'word' && uc $token->[1] eq $word;
  };

  my @out;
  my $at = 0;
  return $plain unless $keyword->($tokens[$at], 'CREATE');
  push @out, 'CREATE';
  $at++;
  if ($keyword->($tokens[$at], 'UNIQUE')) {
    push @out, 'UNIQUE';
    $at++;
  }
  return $plain unless $keyword->($tokens[$at], 'INDEX');
  my $index = $name->($tokens[ $at + 1 ]) // return $plain;
  return $plain unless $keyword->($tokens[ $at + 2 ], 'ON');
  my $table = $name->($tokens[ $at + 3 ]) // return $plain;
  my $open  = $tokens[ $at + 4 ];
  return $plain unless $open && $open->[0] eq 'punct' && $open->[1] eq '(';
  push @out, 'INDEX', $index, 'ON', $table, '(';
  $at += 5;

  # The entries of the column list, split at its own commas.
  my @entry;
  my $depth = 1;
  while ($depth && $at <= $#tokens) {
    my $token = $tokens[ $at++ ];
    my ($kind, $text) = @$token;
    if ($kind eq 'punct') {
      $depth++ if $text eq '(';
      $depth-- if $text eq ')';
      if ($depth == 0 || ($depth == 1 && $text eq ',')) {
        my $single = @entry == 1 ? $name->($entry[0]) : undef;
        push @out, (defined $single ? $single : map { $_->[1] } @entry), $text;
        @entry = ();
        next;
      }
    }
    push @entry, $token;
  }
  return $plain if $depth;

  return join ' ', @out, map { $_->[1] } @tokens[ $at .. $#tokens ];
}


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  # Tables present in the source model but absent from the target are being
  # dropped in this same pass. SQLite's DROP TABLE removes the table's own
  # indexes automatically, so a standalone DROP INDEX for one of them must be
  # suppressed -- it would otherwise fail with "no such index" (karr k14).
  $source_tables //= {};
  $target_tables //= {};
  my %dropped_table = map { $_ => 1 }
    grep { !exists $target_tables->{$_} } keys %$source_tables;

  # Index members are already keyed by name, so no index_by. scope 'all'
  # because an index drop must be emitted even for source-only tables (the
  # generic walk handles that trailing pass). _is_auto skips PK / UNIQUE
  # auto-indexes on both sides. SQLite has no ALTER INDEX, so a changed index
  # is rendered as a drop-then-create pair.
  return $class->diff_nested($source, $target,
    scope        => 'all',
    skip         => \&_is_auto,
    changed_when => sub {
      my ($src, $tgt) = @_;
      my @changed = changed_fields($src, $tgt,
        bool => ['is_unique'],
        dim  => ['columns'],
      );
      # SQLite-specific: also diff the original CREATE INDEX sql (partial
      # / expression indexes) when both sides carry it -- as what it says,
      # with a name read the same however it is quoted.
      if (!@changed && (defined $src->{sql} && defined $tgt->{sql})
          && _comparable_sql($src->{sql}) ne _comparable_sql($tgt->{sql})) {
        push @changed, 'sql';
      }
      scalar @changed;
    },
    on_new => sub {
      my ($table, $name, $new) = @_;
      $class->new(
        action     => 'create',
        table_name => $table,
        index_name => $name,
        index_info => $new,
      );
    },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      (
        $class->new(
          action => 'drop', table_name => $table,
          index_name => $name, index_info => $old, replaced => 1,
        ),
        $class->new(
          action => 'create', table_name => $table,
          index_name => $name, index_info => $new,
        ),
      );
    },
    on_gone => sub {
      my ($table, $name, $old) = @_;
      # Suppress the standalone DROP INDEX when the owning table is itself
      # being dropped this pass: SQLite's DROP TABLE already removed it, so a
      # later DROP INDEX would fail with "no such index" (karr k14).
      return if $dropped_table{$table};
      $class->new(
        action     => 'drop',
        table_name => $table,
        index_name => $name,
        index_info => $old,
      );
    },
  );
}

sub _is_auto {
  my ($info) = @_;
  return 0 unless defined $info->{origin};
  return $info->{origin} eq 'u' || $info->{origin} eq 'pk';
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create') {
    if (my $sql = $self->index_info->{sql}) {
      $sql .= ';' unless $sql =~ /;\s*$/;
      return $sql;
    }
    my $unique = $self->index_info->{is_unique} ? 'UNIQUE ' : '';
    my $cols = join ', ',
      map { quote_identifier($_) } @{ $self->index_info->{columns} // [] };
    return sprintf 'CREATE %sINDEX %s ON %s (%s);',
      $unique,
      quote_identifier($self->index_name),
      quote_identifier($self->table_name),
      $cols;
  }
  return sprintf 'DROP INDEX %s;', quote_identifier($self->index_name);
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %sindex: %s on %s', $prefix, $self->index_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::Index - Diff operations for SQLite indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents an index-level diff operation: C<CREATE INDEX> or
C<DROP INDEX>. SQLite has no C<ALTER INDEX>, so changed definitions
become a drop-then-create pair.

Auto-generated indexes (origin C<u> for UNIQUE constraints, C<pk> for
primary keys) are skipped -- they belong to the table itself, not to
explicit C<CREATE INDEX> statements.

=head2 What counts as a changed index

An index has changed when its uniqueness or its columns differ, and -- for the
sake of what those two do not show, the C<WHERE> of a partial index and the
expressions of an expression index -- when the C<CREATE INDEX> statements of
the two sides differ.

The statements are compared as what they say, not as text. B<How a name is
quoted is no difference>:

    CREATE INDEX idx_name ON item (name) WHERE active = 1
    CREATE INDEX "idx_name" ON "item" ("name") WHERE active = 1

are one index. L<DBIO::SQLite::DDL> wrote the first until it began to quote
every name, so a database deployed before that holds the first and the target
of an upgrade the second; compared as text, every explicit index of every such
database would be dropped and created again, once, for nothing.

What is read that way are the names at the places where the statement can only
have a name: the index, the table, and an entry of the column list that is one
name and nothing else. There C<x>, C<"x">, C<`x`> and C<[x]> are the same.
Whitespace and comments between any two tokens are no difference either.

The letter case of a name is compared as it is written. Everything else has to
be the same, token for token: an entry of the list that is an expression or
carries C<COLLATE>, C<ASC> or C<DESC>, and the whole of the C<WHERE>. That is
the SQL a schema gives as C<expression> and C<where>
(L<DBIO::SQLite::Result>), which L<DBIO::SQLite::DDL> writes as given, so it
comes back the same from an unchanged schema -- and a change in it is a change
of the index, C<WHERE active = 1> against C<WHERE "active" = 1> included: there
a quoted word and a bare one need not mean the same (C<"null"> is a column,
C<null> is not). A string in apostrophes is never read as a name. A statement
that does not begin as a C<CREATE INDEX> is compared with only its whitespace
set aside.

=head1 ATTRIBUTES

=head2 replaced

True on the C<drop> of a changed index: the index is not removed, the
C<create> that follows puts it back with its new definition.
L<DBIO::Diff::Base/classify> counts such a drop as changing, not destructive.
It changes neither the SQL nor the order of the operations.

=head1 METHODS

=head2 diff

    my @ops = DBIO::SQLite::Diff::Index->diff(
      $source, $target, $source_tables, $target_tables);

C<$source> and C<$target> are the C<indexes> sub-models from
L<DBIO::SQLite::Introspect>: C<< { $table_name => { $idx_name => $info } } >>.

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::SQLite::Diff>). They are
used to detect tables that are being dropped in this same diff pass: SQLite's
C<DROP TABLE> automatically removes that table's own indexes, so emitting a
later standalone C<DROP INDEX> for one of them would fail with C<no such index>
and abort the deploy. When these arguments are absent (e.g. direct
unit-test calls) the dropped set is empty and no drops are suppressed,
preserving the original two-argument behaviour.

Which indexes come out as changed is described under
L</What counts as a changed index>.

=head2 as_sql

Returns C<CREATE INDEX> (preferring the original C<sql> from
C<sqlite_master> if available) or C<DROP INDEX>. A statement the op writes
itself has every name quoted (L<DBIO::SQLite::Util/quote_identifier>):
C<DROP INDEX "idx_name";>.

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
