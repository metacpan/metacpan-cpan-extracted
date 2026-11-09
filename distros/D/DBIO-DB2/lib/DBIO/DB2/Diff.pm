package DBIO::DB2::Diff;
# ABSTRACT: Compare two introspected DB2 models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';

use DBIO::DB2::Diff::Table;
use DBIO::DB2::Diff::Column;
use DBIO::DB2::Diff::Reorg;
use DBIO::DB2::Diff::Index;
use DBIO::DB2::Diff::UniqueConstraint;
use DBIO::DB2::Diff::ForeignKey;
use DBIO::DB2::Diff::View;


sub _build_operations {
  my ($self) = @_;
  my @ops;

  # Views are no tables (karr k45, ADR 0011): the ops of a view are a DROP VIEW
  # at the head -- a table a view reads can then go -- and a CREATE VIEW at the
  # end, behind the tables, columns and keys it reads. Diff::Table and
  # Diff::Column leave every entry of kind view alone.
  my @view_ops = DBIO::DB2::Diff::View->diff(
    $self->source->{tables}, $self->target->{tables},
  );
  push @ops, grep { $_->action eq 'drop' } @view_ops;

  push @ops, DBIO::DB2::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
    $self->target->{unique_constraints},
  );
  my @column_ops = DBIO::DB2::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, @column_ops;
  # One REORG per table the column pass leaves reorg-pending, before the first
  # statement such a table refuses: a CREATE INDEX of the next pass
  # (SQL0668N rc 7, karr k42).
  push @ops, DBIO::DB2::Diff::Reorg->diff(@column_ops);
  # Index::diff also needs the tables sections to detect which tables are being
  # dropped in this same pass, so it can suppress a standalone DROP INDEX that
  # DROP TABLE already covers (DB2 drops a table's own indexes with it -- karr k19).
  push @ops, DBIO::DB2::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
    $self->source->{tables},  $self->target->{tables},
    $self->target->{columns}, $self->target->{unique_constraints},
    $self->source->{columns},
  );
  # UNIQUE constraints of tables present on both sides (those of a new table are
  # inline in its CREATE TABLE): after the indexes, before the FKs (karr k39,
  # ADR 0009).
  push @ops, DBIO::DB2::Diff::UniqueConstraint->diff(
    $self->source->{unique_constraints}, $self->target->{unique_constraints},
    $self->source->{tables},             $self->target->{tables},
    $self->source->{columns},            $self->target->{columns},
  );
  push @ops, DBIO::DB2::Diff::ForeignKey->diff(
    $self->source->{foreign_keys}, $self->target->{foreign_keys},
    $self->source->{tables},       $self->target->{tables},
  );
  push @ops, grep { $_->action eq 'create' } @view_ops;

  return \@ops;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Diff - Compare two introspected DB2 models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::DB2::Diff> compares two introspected DB2 models (produced
by L<DBIO::DB2::Introspect>) and emits a list of structured diff
operations that can be rendered to SQL or a human-readable summary.

    my $diff = DBIO::DB2::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: the views that are dropped (or
dropped to be replaced) first, then tables, then columns, then the
C<REORG> some column changes make necessary, then indexes, then unique constraints, then foreign keys.
New-table unique constraints and FKs are created inline by
L<DBIO::DB2::Diff::Table>; L<DBIO::DB2::Diff::ForeignKey> handles FK changes
on tables present in both models. FKs come last so any referenced table or
column already exists. Drops come last for each layer. The views that are created
come after everything else. A view is no table: it has operations of its own
(L<DBIO::DB2::Diff::View>), a changed definition is a C<DROP VIEW> and a
C<CREATE VIEW> around all of it (ADR 0011).

=head2 REORG after the column pass

C<DROP COLUMN>, C<SET NOT NULL>, C<DROP NOT NULL> and nearly every
C<SET DATA TYPE> leave a Db2 table in reorg-pending state, in which the server
refuses C<INSERT>, C<UPDATE> and C<CREATE INDEX> on it (SQL0668N rc 7). So
after the column pass every table with such an operation
(L<DBIO::DB2::Diff::Column/reorg_recommended>) gets one
L<DBIO::DB2::Diff::Reorg> operation -- C<CALL SYSPROC.ADMIN_CMD('REORG TABLE
...')> -- and the index and foreign key passes run on a table that takes them.
The C<REORG> is in L<DBIO::Diff::Base/as_sql> and L<DBIO::Diff::Base/summary>
like any other operation: it rewrites the table, and a diff is where an
operator reads what an upgrade is going to do. A table that is already
reorg-pending before the diff is made gets none; see L<DBIO::DB2::Diff::Reorg>
and ADR 0008.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
