package DBIO::MSSQL::Diff::ForeignKey;
# ABSTRACT: Diff operations for MSSQL foreign keys

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Diff::Compare qw(changed_fields);


__PACKAGE__->mk_diff_accessors(qw/table_name constraint_name fk_info/);


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  return $class->diff_nested($source, $target,
    index_by      => 'constraint_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub {
      scalar changed_fields($_[0], $_[1],
        scalar => ['to_table', 'on_delete', 'on_update'],
        dim     => ['from_columns', 'to_columns']);
    },
    on_new => sub {
      my ($table, $name, $new) = @_;
      $class->new(action => 'add', table_name => $table,
        constraint_name => $name, fk_info => $new);
    },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      ($class->new(action => 'drop', table_name => $table,
         constraint_name => $name, fk_info => $old),
       $class->new(action => 'add', table_name => $table,
         constraint_name => $name, fk_info => $new));
    },
    on_gone => sub {
      my ($table, $name, $old) = @_;
      $class->new(action => 'drop', table_name => $table,
        constraint_name => $name, fk_info => $old);
    },
  );
}


sub as_sql {
  my ($self) = @_;
  my $tbl  = _quote_ident($self->table_name);
  my $name = _quote_ident($self->constraint_name);

  if ($self->action eq 'add') {
    my $info = $self->fk_info;
    my $from = join(', ', map { _quote_ident($_) } @{ $info->{from_columns} });
    my $to   = join(', ', map { _quote_ident($_) } @{ $info->{to_columns} });
    my $sql  = sprintf
      'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)',
      $tbl, $name, $from, _quote_ident($info->{to_table}), $to;
    $sql .= " ON DELETE $info->{on_delete}"
      if $info->{on_delete} && $info->{on_delete} ne 'NO ACTION';
    $sql .= " ON UPDATE $info->{on_update}"
      if $info->{on_update} && $info->{on_update} ne 'NO ACTION';
    return "$sql;";
  }
  return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', $tbl, $name;
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sfk: %s on %s',
    $self->summary_prefix, $self->constraint_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Diff::ForeignKey - Diff operations for MSSQL foreign keys

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents a foreign key diff operation: C<ADD CONSTRAINT> or
C<DROP CONSTRAINT>. FKs on a brand-new table are created inline by
L<DBIO::MSSQL::Diff::Table>; this module handles FK changes on tables that
exist in both source and target. Built on L<DBIO::Diff::Op>.

FK identity is by C<constraint_name>. MSSQL has no C<ALTER> for a foreign
key, so a definition change becomes a drop-then-add pair. Local and remote
column lists are order-significant, so they are compared as C<dim> fields.

=head1 METHODS

=head2 diff

    my @ops = DBIO::MSSQL::Diff::ForeignKey->diff(
        $source_fks, $target_fks, $source_tables, $target_tables,
    );

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
