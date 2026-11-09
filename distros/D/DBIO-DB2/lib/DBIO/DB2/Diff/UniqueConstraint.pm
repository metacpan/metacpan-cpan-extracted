package DBIO::DB2::Diff::UniqueConstraint;
# ABSTRACT: Diff operations for DB2 unique constraints

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::DB2::DDL qw(_unique_constraint_clause _db2_quote_ident _db2_quote_table);


__PACKAGE__->mk_diff_accessors(qw/table_name constraint_name columns/);


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $source_columns, $target_columns) = @_;
  $source        //= {};
  $target        //= {};
  $source_tables //= {};
  $target_tables //= {};

  # diff_nested walks the tables of the target section: give every table the
  # models share an entry on both sides, so a table whose last constraint left
  # the schema still gets its drop.
  # Db2 drops a UNIQUE constraint together with a column it covers (DROP COLUMN), so
  # ALTER TABLE ... DROP UNIQUE behind it finds nothing (SQL0204N, karr k57): no
  # drop is written for a constraint over a column this pass drops.
  my $dropped = sub {
    my ($table, $cols) = @_;
    return 0 unless $source_columns && $source_columns->{$table};
    my %kept = map { $_->{column_name} => 1 } @{ ($target_columns // {})->{$table} // [] };
    my %gone = map { $_->{column_name} => 1 }
      grep { !$kept{ $_->{column_name} } } @{ $source_columns->{$table} };
    return (grep { $gone{$_} } @$cols) ? 1 : 0;
  };
  my (%src, %tgt);
  for my $table (grep { exists $target_tables->{$_} } keys %$source_tables) {
    $src{$table} = _by_name($source->{$table});
    $tgt{$table} = _by_name($target->{$table});
  }

  return $class->diff_nested(\%src, \%tgt,
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub {
      join("\0", @{ $_[0]{columns} }) ne join("\0", @{ $_[1]{columns} });
    },
    on_new => sub {
      my ($table, $name, $new) = @_;
      $class->new(action => 'add', table_name => $table,
        constraint_name => $name, columns => $new->{columns});
    },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      ($dropped->($table, $old->{columns}) ? () :
         $class->new(action => 'drop', table_name => $table,
           constraint_name => $name, columns => $old->{columns}),
       $class->new(action => 'add', table_name => $table,
         constraint_name => $name, columns => $new->{columns}));
    },
    on_gone => sub {
      my ($table, $name, $old) = @_;
      return if $dropped->($table, $old->{columns});
      $class->new(action => 'drop', table_name => $table,
        constraint_name => $name, columns => $old->{columns});
    },
  );
}

sub _by_name {
  my ($pairs) = @_;
  return { map { $_->[0] => { constraint_name => $_->[0], columns => $_->[1] } } @{ $pairs || [] } };
}


sub as_sql {
  my ($self) = @_;
  my $tbl = _db2_quote_table($self->table_name);

  if ($self->action eq 'add') {
    return sprintf 'ALTER TABLE %s ADD %s;', $tbl,
      _unique_constraint_clause($self->constraint_name, $self->columns);
  }
  return sprintf 'ALTER TABLE %s DROP UNIQUE %s;', $tbl,
    _db2_quote_ident($self->constraint_name);
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sunique: %s on %s',
    $self->summary_prefix, $self->constraint_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Diff::UniqueConstraint - Diff operations for DB2 unique constraints

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a unique constraint diff operation: C<ADD CONSTRAINT ... UNIQUE> or
C<DROP UNIQUE>. The constraints of a brand-new table are created inline by
L<DBIO::DB2::Diff::Table>; this module handles tables that exist in both
models. Built on L<DBIO::Diff::Op>.

Identity is by constraint name. Db2 has no C<ALTER> for the columns of a
constraint, so a change becomes a drop-then-add pair (drop first). The index Db2
keeps behind a constraint goes with C<DROP UNIQUE> and comes with
C<ADD CONSTRAINT>; L<DBIO::DB2::Introspect::Indexes> does not report it, so
L<DBIO::DB2::Diff::Index> never sees it (ADR 0009).

=head1 METHODS

=head2 diff

    my @ops = DBIO::DB2::Diff::UniqueConstraint->diff(
        $source_ucs, $target_ucs, $source_tables, $target_tables,
    );

The two sections are the C<unique_constraints> of the models,
C<< { $table => [ [ $name, \@columns ], ... ] } >>; either may be C<undef>
(a model older than the section). A table in both models but without an entry
in one section is a table without constraints there.

=head2 as_sql

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
