package DBIO::Oracle::Diff::ForeignKey;
# ABSTRACT: Diff operations for Oracle foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::Oracle::Identifier ();

__PACKAGE__->mk_diff_accessors(qw(table_name constraint_name fk_info));



# A signature of a foreign key that does not depend on the constraint name.
sub _signature {
  my ($fk) = @_;
  my $norm = sub {
    my $rule = uc( $_[0] // 'NO ACTION' );
    return $rule eq 'RESTRICT' ? 'NO ACTION' : $rule;
  };
  return join "\x1f",
    join(',', @{ $fk->{from_columns} // [] }),
    $fk->{to_table} // '',
    join(',', @{ $fk->{to_columns} // [] }),
    $norm->($fk->{on_delete}),
    $norm->($fk->{on_update}),
    $fk->{is_deferrable} ? 1 : 0;
}


sub create_op {
  my ($class, $table, $fk) = @_;
  my @from = @{ $fk->{from_columns} // [] };
  my $name = $fk->{constraint_name}
    // DBIO::Oracle::Identifier::shorten(join '_', 'fk',
      (DBIO::Oracle::Identifier::split_table($table))[1], @from,
      (DBIO::Oracle::Identifier::split_table($fk->{to_table}))[1]);

  # Oracle's delete rules are NO ACTION (RESTRICT is the same), CASCADE and
  # SET NULL and it has no ON UPDATE; anything else is not written in silence.
  my $where = sprintf "the foreign key '%s' of table '%s' (column%s %s)",
    $name, $table, (@from > 1 ? 's' : ''), join(', ', @from);
  my $rule = uc( $fk->{on_delete} // 'NO ACTION' );
  DBIO::Exception->throw(
    "DBIO::Oracle::Diff: $where has the delete rule '$fk->{on_delete}', "
    . 'which Oracle does not have (ON DELETE takes CASCADE and SET NULL)')
    unless $rule =~ /\A(?:NO ACTION|RESTRICT|CASCADE|SET NULL)\z/;
  DBIO::Exception->throw(
    "DBIO::Oracle::Diff: $where has the update rule '$fk->{on_update}', "
    . 'which Oracle does not have (Oracle has no ON UPDATE)')
    if defined $fk->{on_update} && $fk->{on_update} !~ /\A(?:NO ACTION|RESTRICT)\z/i;

  return $class->new(
    action          => 'create',
    table_name      => $table,
    constraint_name => $name,
    fk_info         => $fk,
  );
}

sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $target_columns) = @_;
  $source         ||= {};
  $target         ||= {};
  $source_tables  ||= $source;
  $target_tables  ||= $target;
  $target_columns ||= {};

  my $create = sub { $class->create_op(@_) };

  my @ops;
  my %walk = map { $_ => 1 } keys %$source, keys %$target;
  for my $table (sort keys %walk) {
    next unless exists $target_tables->{$table};
    my @target_fks = @{ $target->{$table} // [] };

    # a table only the target has: all of its keys are new
    unless (exists $source_tables->{$table}) {
      push @ops, map { $create->($table, $_) } @target_fks;
      next;
    }

    my %have = map { _signature($_) => 1 } @{ $source->{$table} // [] };
    my %want = map { _signature($_) => 1 } @target_fks;

    # a key over a column the target drops goes with the column
    my $kept = $target_columns->{$table}
      ? { map { lc($_->{column_name}) => 1 } @{ $target_columns->{$table} } } : undef;

    for my $fk (@{ $source->{$table} // [] }) {
      next if $want{ _signature($fk) };
      next if $kept && grep { !$kept->{ lc $_ } } @{ $fk->{from_columns} // [] };
      push @ops, $class->new(
        action          => 'drop',
        table_name      => $table,
        constraint_name => $fk->{constraint_name},
        fk_info         => $fk,
      );
    }
    push @ops, map { $create->($table, $_) } grep { !$have{ _signature($_) } } @target_fks;
  }
  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $q  = \&DBIO::Oracle::Identifier::quote;
  my $fk = $self->fk_info;

  return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;',
    DBIO::Oracle::Identifier::quote_table($self->table_name), $q->($self->constraint_name)
    if $self->action eq 'drop';

  my $rule = uc( $fk->{on_delete} // 'NO ACTION' );
  $rule = 'NO ACTION' if $rule eq 'RESTRICT';
  return sprintf 'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s (%s)%s%s;',
    DBIO::Oracle::Identifier::quote_table($self->table_name), $q->($self->constraint_name),
    join(', ', map { $q->($_) } @{ $fk->{from_columns} }),
    DBIO::Oracle::Identifier::quote_table($fk->{to_table}),
    join(', ', map { $q->($_) } @{ $fk->{to_columns} }),
    ( $rule eq 'NO ACTION' ? '' : " ON DELETE $rule" ),
    ( $fk->{is_deferrable} ? ' DEFERRABLE' : '' );
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sforeign key: %s on %s',
    $self->summary_prefix, $self->constraint_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff::ForeignKey - Diff operations for Oracle foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Creates the foreign keys of a table that only the target model has, each as an
C<ALTER TABLE ... ADD CONSTRAINT> after every C<CREATE TABLE> of the diff: a
new table may point to one that is created after it, or to itself, so no table
order would do (L<DBIO::Oracle::DDL> does the same).

The foreign keys of a table both models have are compared. A key is
what it is, not what it is called: its columns, the referenced table and
columns, C<on_delete>, C<on_update> and C<is_deferrable>; the names of the
constraints do not count, and a missing section counts as empty. A key only the
source has is dropped (C<ALTER TABLE ... DROP CONSTRAINT>, by the name the
introspected source model gives it), one only the target has is added, and a
key that changed (an action, the columns, the target) is both, the drop first.
A key over a column the target drops is not dropped here: the column goes with
C<CASCADE CONSTRAINTS> (L<DBIO::Oracle::Diff::Column>).

The statement is the one the install writes: the name of the constraint, the
columns, the referenced table and columns, C<ON DELETE CASCADE> or C<ON DELETE
SET NULL> (C<NO ACTION> is Oracle's behaviour and writes nothing; C<RESTRICT> is written
as C<NO ACTION>, as the DDL does) and
C<DEFERRABLE> for a deferrable key. The name is the one of the model; a key
without one gets the install's,
C<fk_E<lt>tableE<gt>_E<lt>columnsE<gt>_E<lt>targetE<gt>> shortened to 30
characters. Oracle has no C<ON UPDATE> and no C<ON DELETE SET DEFAULT>: a key
to be created with one is refused with a L<DBIO::Exception> naming the table and
the columns, as L<DBIO::Oracle::DDL> refuses it.

=head1 ATTRIBUTES

=head2 table_name

The key of the table that holds the key: a bare name, or C<schema.table>.

=head2 constraint_name

The name of the constraint.

=head2 fk_info

Hashref of the key from the model: C<from_columns>, C<to_table>,
C<to_columns>, C<on_delete>, C<on_update>, C<is_deferrable>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Oracle::Diff::ForeignKey->diff(
        $source_fks, $target_fks, $source_tables, $target_tables, $target_columns,
    );

The C<foreign_keys> sections of the two models (keyed by table, each an
arrayref of keys), their C<tables> and the C<columns> section of the target
(which columns a table keeps). For a table in both table sets: a C<drop> op
for each key only the source has and a C<create> op for each key only the
target has. For a table only in the target tables: a C<create> op for each of
its keys. In the order of the table names and of the keys of the model; the
drops of a table come before its creates.

=head2 create_op

    my $op = DBIO::Oracle::Diff::ForeignKey->create_op($table, $fk);

The C<create> op for the key C<$fk> of the model on C<$table>, with the checks
of C<diff>: a delete or update rule Oracle does not have throws a
L<DBIO::Exception> naming the table and the columns. C<on_delete RESTRICT> is
Oracle's C<NO ACTION> and written as such (no clause), as L<DBIO::Oracle::DDL>
does.

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
