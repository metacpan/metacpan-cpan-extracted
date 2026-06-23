package DBIO::DB2::Diff::ForeignKey;
# ABSTRACT: Diff operations for DB2 foreign keys

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Diff::Compare qw(changed_fk_fields);
use DBIO::DB2::DDL qw(_fk_constraint_clause);


__PACKAGE__->mk_diff_accessors(qw/table_name constraint_name fk_info/);


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  return $class->diff_nested($source, $target,
    index_by      => 'constraint_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub { scalar changed_fk_fields($_[0], $_[1]) },
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
    # Same FK clause body as the inline create path -- single source of truth
    # in DBIO::DB2::DDL (ADR 0005), here wrapped in ALTER TABLE ... ADD.
    my $clause = _fk_constraint_clause($self->fk_info);
    return sprintf 'ALTER TABLE %s ADD %s;', $tbl, $clause;
  }
  return sprintf 'ALTER TABLE %s DROP FOREIGN KEY %s;', $tbl, $name;
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

DBIO::DB2::Diff::ForeignKey - Diff operations for DB2 foreign keys

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents a foreign key diff operation: C<ADD CONSTRAINT> or
C<DROP FOREIGN KEY>. FKs on a brand-new table are created inline by
L<DBIO::DB2::Diff::Table>; this module handles FK changes on tables that
exist in both source and target. Built on L<DBIO::Diff::Op>.

FK identity is by C<constraint_name>. DB2 has no C<ALTER> for a foreign key
definition, so a change becomes a drop-then-add pair (drop first). The
deterministic FK name emitted by L<DBIO::DB2::DDL> round-trips through
introspection, so source and target carry the same stable name and the
name-based match does not phantom-diff (see ADR 0005). The C<DROP> uses the
real server name carried in the model.

=head1 METHODS

=head2 diff

    my @ops = DBIO::DB2::Diff::ForeignKey->diff(
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
