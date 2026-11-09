package DBIO::Informix::Diff;
# ABSTRACT: Compare two introspected Informix models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';

use DBIO::Informix::Diff::Table;
use DBIO::Informix::Diff::Column;
use DBIO::Informix::Diff::Index;
use DBIO::Informix::Diff::ForeignKey;
use DBIO::Informix::Diff::UniqueConstraint;
use DBIO::Informix::Diff::PrimaryKey;


sub _build_operations {
  my ($self) = @_;

  my @tables = DBIO::Informix::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns},
  );
  my @columns = DBIO::Informix::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  my @indexes = DBIO::Informix::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
  );
  my @uniques = DBIO::Informix::Diff::UniqueConstraint->diff(
    $self->source->{unique_constraints}, $self->target->{unique_constraints},
    $self->source->{tables},             $self->target->{tables},
  );
  my @pks = DBIO::Informix::Diff::PrimaryKey->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  # a key that stays over a primary key or constraint dropped here is dropped
  # before it and added again (karr k27, k28)
  my @fks = DBIO::Informix::Diff::ForeignKey->diff(
    $self->source->{foreign_keys}, $self->target->{foreign_keys},
    $self->source->{tables},       $self->target->{tables},
    DBIO::Informix::Diff::UniqueConstraint->dropped_keys(@uniques, @pks),
  );

  # A view is dropped before anything it may read from is changed and
  # created after everything it reads from exists.
  my @view_drops   = grep { $_->isa('DBIO::Informix::Diff::Table') && $_->is_view && $_->action eq 'drop' } @tables;
  my @view_creates = grep { $_->isa('DBIO::Informix::Diff::Table') && $_->is_view && $_->action ne 'drop' } @tables;
  @tables = grep { !$_->is_view } @tables;

  # A view that reads another is dropped before and created after it, where
  # its definition names the other, whatever the alphabet says.
  my $def_of = sub { my ($op) = @_; $op->table_info->{definition} // '' };
  my $order = sub {
    my ($ops, $reverse) = @_;
    my %op = map { $_->table_name => $_ } @$ops;
    my @names = DBIO::Diff::Op::_order_by_dependency(sub {
      my $src = $def_of->($op{ $_[0] });
      [ grep { $_ ne $_[0] && $src =~ /(?<![\w\$])\Q$_\E(?![\w\$])/i } keys %op ];
    }, keys %op);
    @names = reverse @names if $reverse;
    return map { $op{$_} } @names;
  };
  @view_drops   = $order->(\@view_drops, 1);
  @view_creates = $order->(\@view_creates, 0);

  # Dropping a column drops the constraints and indexes on it, dropping a
  # table drops its indexes: a DROP CONSTRAINT / DROP INDEX behind either
  # fails (-623 / -319, measured on Informix 15.0.1, karr k20). So the drops
  # of foreign keys and indexes lead, their creation trails.
  return [
    @view_drops,
    (grep { $_->action eq 'drop' } @fks),
    (grep { $_->action eq 'drop' } @pks),
    (grep { $_->action eq 'drop' } @uniques),
    (grep { $_->action eq 'drop' } @indexes),
    @tables,
    @columns,
    (grep { $_->action ne 'drop' } @pks),
    (grep { $_->action ne 'drop' } @uniques),
    (grep { $_->action ne 'drop' } @indexes),
    (grep { $_->action ne 'drop' } @fks),
    @view_creates,
  ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Diff - Compare two introspected Informix models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Informix::Diff> compares two introspected Informix models (produced
by L<DBIO::Informix::Introspect>) and emits a list of structured diff
operations that can be rendered to SQL or a human-readable summary.

    my $diff = DBIO::Informix::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in an order the server can run: first the drops of
foreign keys (L<DBIO::Informix::Diff::ForeignKey>) and indexes (dropping a
column or table takes its indexes and constraints along, so a drop behind it
fails), then tables, then columns, then the new primary keys and unique
constraints, indexes and foreign keys. Views are dropped first and created last.

A foreign key that stays but references a primary key or unique constraint
dropped (or changed) in the same diff goes first as well and is added again
last: the server takes the key along with the constraint, and a later C<DROP
CONSTRAINT> of the key fails with -623. The primary key is
compared by the columns the model flags (C<is_pk>, C<pk_position>) in key
order, see L<DBIO::Informix::Diff::PrimaryKey>: a changed key is dropped
with the unique constraints to drop and added before the unique constraints
to add.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
