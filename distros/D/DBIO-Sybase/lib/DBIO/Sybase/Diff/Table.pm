package DBIO::Sybase::Diff::Table;
# ABSTRACT: Diff Sybase ASE tables

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();
use DBIO::Diff::Op ();
use DBIO::Sybase::Quote ();
use DBIO::Sybase::DDL ();


sub diff {
  my ($class, $source, $target, $target_columns, $target_fks) = @_;
  $target_columns //= {};
  $target_fks     //= {};
  my @ops;

  for my $name (sort keys %$target) {
    # A view is DBIO::Sybase::Diff::View's (karr k98): CREATE TABLE for it
    # would be a table of the same name, and the columns of a view are the
    # query's.
    next if _is_view($target->{$name});
    # Existing tables are reconciled column-by-column and index-by-index by
    # DBIO::Sybase::Diff::Column / ::Index. There is no table-level ALTER op:
    # Sybase ASE cannot convert a table to a view (or vice versa) in place, so
    # a kind change is left for a human rather than emitting a broken stub.
    next if exists $source->{$name};
    push @ops, DBIO::Sybase::Diff::Table::Create->new(
      action  => 'create',
      table   => $target->{$name},
      columns => $target_columns->{$name} // [],
    );
  }

  for my $name (sort keys %$source) {
    next if _is_view($source->{$name});
    push @ops, DBIO::Sybase::Diff::Table::Drop->new(
      action => 'drop',
      table  => $source->{$name},
    ) unless exists $target->{$name};
  }

  return @ops;
}

# A view is listed with the tables of a model (kind => 'view'), and is the
# business of DBIO::Sybase::Diff::View.
sub _is_view { ($_[0]{kind} // '') eq 'view' }


sub diff_primary_keys {
  my ($class, $s_tables, $t_tables, $s_cols, $t_cols, $s_indexes) = @_;
  $_ //= {} for $s_tables, $t_tables, $s_cols, $t_cols, $s_indexes;
  my @ops;

  for my $name (sort keys %$t_tables) {
    next unless exists $s_tables->{$name};
    my @from = _pk_columns($s_cols->{$name});
    my @to   = _pk_columns($t_cols->{$name});
    next if join("\0", @from) eq join("\0", @to);

    if (@from) {
      my ($pk) = grep { ($_->{origin} // '') eq 'pk' }
        values %{ $s_indexes->{$name} // {} };
      push @ops, DBIO::Sybase::Diff::Table::PrimaryKey::Drop->new(
        action          => 'drop',
        table_name      => $name,
        constraint_name => $pk ? $pk->{index_name} : undef,
        columns         => \@from,
      );
    }
    push @ops, DBIO::Sybase::Diff::Table::PrimaryKey::Add->new(
      action     => 'create',
      table_name => $name,
      columns    => \@to,
    ) if @to;
  }

  return @ops;
}

# The key columns of one table's column list, in key order. pk_position is
# what the catalog reports; a column marked is_pk without one (a hand-written
# model) keeps its place in the column list.
sub _pk_columns {
  my ($cols) = @_;
  my $i = 0;
  my @pk = map { [ $_->{pk_position} || 1e9, $i++, $_->{column_name} ] }
    grep { $_->{is_pk} } @{ $cols // [] };
  return map { $_->[2] } sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @pk;
}

package DBIO::Sybase::Diff::Table::Create;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table columns));

sub as_sql {
  my $self = shift;
  my $tbl = DBIO::Sybase::Quote::quote_ident($self->table->{table_name});
  my @col_defs;

  my $cols = $self->columns // [];
  for my $col (@$cols) {
    my $type = DBIO::Sybase::DDL::sybase_column_type($col->{data_type}, $col->{size});
    my $def  = sprintf '  %s %s',
      DBIO::Sybase::Quote::quote_ident($col->{column_name}), $type;
    # Same column grammar and same rules as DBIO::Sybase::DDL::install_ddl
    # (karr k47): DEFAULT before the nullability, IDENTITY as the lone
    # attribute, and a nullable column spelled NULL rather than left to the
    # database's "allow nulls by default" option. IDENTITY on an integer
    # or NUMERIC(p,0) column only (karr k52) -- any other known type croaks, see
    # DBIO::Sybase::DDL::_identity_clause.
    if ($col->{is_auto_increment}) {
      push @col_defs, $def . DBIO::Sybase::DDL::_identity_clause(
        $type, $col->{data_type}, $col->{column_name}, $self->table->{table_name});
      next;
    }
    $def .= DBIO::Sybase::DDL::sybase_default_clause(
      $col->{default_value}, $col->{data_type}, $col->{column_name});
    $def .= $col->{not_null} ? ' NOT NULL' : ' NULL';
    push @col_defs, $def;
  }

  # The key, in key order (karr k53) -- same clause install_ddl writes.
  my @pk = DBIO::Sybase::Diff::Table::_pk_columns($cols);
  push @col_defs, sprintf '  PRIMARY KEY (%s)',
    join(', ', map { DBIO::Sybase::Quote::quote_ident($_) } @pk)
    if @pk;

  sprintf "CREATE TABLE %s (\n%s\n);", $tbl, join(",\n", @col_defs);
}
sub summary {
  my $self = shift;
  "CREATE TABLE " . $self->table->{table_name};
}

package DBIO::Sybase::Diff::Table::Drop;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table));

sub as_sql {
  my $self = shift;
  "DROP TABLE " . DBIO::Sybase::Quote::quote_ident($self->table->{table_name}) . ';';
}
sub summary {
  my $self = shift;
  "DROP TABLE " . $self->table->{table_name};
}

package DBIO::Sybase::Diff::Table::PrimaryKey::Drop;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table_name constraint_name columns));

sub as_sql {
  my $self = shift;
  my $tbl = $self->table_name;
  # The name comes from the source side's PK index -- the introspected live
  # database always has one. Without it there is nothing ASE would accept.
  Carp::croak(
    "DBIO::Sybase: no primary-key constraint name for table $tbl in the "
      . 'source model (its origin => pk index is missing), cannot drop the key')
    unless defined $self->constraint_name && length $self->constraint_name;
  sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;',
    DBIO::Sybase::Quote::quote_ident($tbl),
    DBIO::Sybase::Quote::quote_ident($self->constraint_name);
}
sub summary {
  my $self = shift;
  sprintf 'DROP PRIMARY KEY ON %s (%s)', $self->table_name, join(', ', @{ $self->columns });
}

package DBIO::Sybase::Diff::Table::PrimaryKey::Add;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table_name columns));

sub as_sql {
  my $self = shift;
  sprintf 'ALTER TABLE %s ADD PRIMARY KEY (%s);',
    DBIO::Sybase::Quote::quote_ident($self->table_name),
    join(', ', map { DBIO::Sybase::Quote::quote_ident($_) } @{ $self->columns });
}
sub summary {
  my $self = shift;
  sprintf 'ADD PRIMARY KEY ON %s (%s)', $self->table_name, join(', ', @{ $self->columns });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff::Table - Diff Sybase ASE tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Compares two table sets and generates table-level diff operations.

=head1 METHODS

=head2 diff_primary_keys

    my @ops = DBIO::Sybase::Diff::Table->diff_primary_keys(
      $source_tables, $target_tables,
      $source_columns, $target_columns, $source_indexes,
    );

Primary-key ops for the tables present on both sides: a
C<DBIO::Sybase::Diff::Table::PrimaryKey::Drop> (action C<drop>) when the
source has a key that differs from the target's or the target has none, and a
C<...::PrimaryKey::Add> (action C<create>) when the target has a key that
differs from the source's or the source has none. See
L</THE PRIMARY KEY IS PART OF THE TABLE>.

=head1 THE PRIMARY KEY IS PART OF THE TABLE

A created table carries its C<PRIMARY KEY> in the C<CREATE TABLE>, columns in
C<pk_position> order -- the key order the catalog reports, which
L<DBIO::Sybase::Introspect> marks on the columns. A table added through
L<DBIO::Sybase::Deploy/upgrade> keeps its key.

For a table on both sides L</diff_primary_keys> compares the key as the
B<ordered column list>, never by name: ASE names the constraint after the
object id (C<artist_5760020521>), so the live name and the one in the compare
database never agree (the same reason L<DBIO::Sybase::Diff::Index> leaves the
PK index out). A changed, added or removed key becomes

    ALTER TABLE t DROP CONSTRAINT <live name>;
    ALTER TABLE t ADD PRIMARY KEY (a, b);

-- the drop naming the source side's PK index, which in ASE B<is> the
constraint (it is not listed in C<sysconstraints>). ASE has no in-place change
and refuses a second key (Msg 1923), so it is always the drop and then the
add, both accepted on ASE 16.0 SP02. L<DBIO::Sybase::Diff> places the drop
before the column diff (a key column may be about to be dropped) and the add
after it (a key column may be about to be added, or made C<NOT NULL>).

A key still referenced by a foreign key cannot be dropped (Msg 3712 "Cannot
drop index ... because it still has referential integrity constraints"). The
diff drops a foreign key only when the desired model no longer has it, so a
key change under an unchanged reference fails at that statement.

=head1 IDENTITY ON A NUMERIC COLUMN ONLY

A column marked C<is_auto_increment> is created C<< <type> IDENTITY >>. ASE
takes that attribute on an integer or C<NUMERIC(p,0)> column only, so the
C<CREATE TABLE> of a table with such a column of a type known not to take it
is refused --
C<as_sql> C<croak>s naming table, column and type -- under the rule and with
the type list of L<DBIO::Sybase::DDL/install_ddl>, the other emitter
of this column grammar.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
