package DBIO::Oracle::Diff::Unique;
# ABSTRACT: Diff operations for the unique constraints of Oracle tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Oracle::Identifier ();

__PACKAGE__->mk_diff_accessors(qw(table_name constraint_name columns));



sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $target_columns) = @_;
  $source         ||= {};
  $target         ||= {};
  $source_tables  ||= $source;
  $target_tables  ||= $target;
  $target_columns ||= {};

  my $sig = sub { join "\x1f", @{ $_[0][1] // [] } };

  my @ops;
  my %walk = map { $_ => 1 } keys %$source, keys %$target;
  for my $table (sort keys %walk) {
    next unless exists $source_tables->{$table} && exists $target_tables->{$table};
    my @src = @{ $source->{$table} // [] };
    my @tgt = @{ $target->{$table} // [] };
    my %have = map { $sig->($_) => 1 } @src;
    my %want = map { $sig->($_) => 1 } @tgt;

    # a constraint over a column the target drops goes with the column
    my $kept = $target_columns->{$table}
      ? { map { lc($_->{column_name}) => 1 } @{ $target_columns->{$table} } } : undef;

    for my $uc (grep { !$want{ $sig->($_) } } @src) {
      next if $kept && grep { !$kept->{ lc $_ } } @{ $uc->[1] // [] };
      push @ops, $class->new(
        action => 'drop', table_name => $table,
        constraint_name => $uc->[0], columns => $uc->[1],
      );
    }
    for my $uc (grep { !$have{ $sig->($_) } } @tgt) {
      push @ops, $class->new(
        action => 'create', table_name => $table,
        constraint_name => $uc->[0], columns => $uc->[1],
      );
    }
  }
  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $q   = \&DBIO::Oracle::Identifier::quote;
  my $tbl = DBIO::Oracle::Identifier::quote_table($self->table_name);

  return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', $tbl, $q->($self->constraint_name)
    if $self->action eq 'drop';

  return sprintf 'ALTER TABLE %s ADD CONSTRAINT %s UNIQUE (%s);',
    $tbl, $q->($self->constraint_name), join(', ', map { $q->($_) } @{ $self->columns });
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sunique constraint: %s on %s',
    $self->summary_prefix, $self->constraint_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff::Unique - Diff operations for the unique constraints of Oracle tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Compares the unique constraints (the C<unique_constraints> section of the
models, per table a list of C<[ $name, \@columns ]> pairs) of a table both
models have and writes the difference: C<ALTER TABLE ... DROP
CONSTRAINT> for a constraint only the source has, C<ALTER TABLE ... ADD
CONSTRAINT ... UNIQUE> for one only the target has, and both, the drop first,
for a constraint whose columns changed.

A constraint is its columns, in order: the names do not count, and a missing
section counts as empty. The drop uses the name of the introspected source
model, the add the name of the target model (the one L<DBIO::Oracle::DDL>
gave it in the install). A constraint over a column the target drops is not
dropped here: the column goes with C<CASCADE CONSTRAINTS>
(L<DBIO::Oracle::Diff::Column>). The unique constraints of a table that only
the target has are written inline by L<DBIO::Oracle::Diff::Table>.

=head1 ATTRIBUTES

=head2 table_name

The key of the table: a bare name, or C<schema.table>.

=head2 constraint_name

The name of the constraint.

=head2 columns

ArrayRef of the column names of the constraint.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Oracle::Diff::Unique->diff(
        $source_unique, $target_unique, $source_tables, $target_tables, $target_columns,
    );

The C<unique_constraints> sections of the two models, their C<tables> and the
C<columns> section of the target. Returns C<drop> and C<create> ops for each
table both table sets have, in the order of the table names and of the
constraints of the model, the drops of a table before its creates.

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
