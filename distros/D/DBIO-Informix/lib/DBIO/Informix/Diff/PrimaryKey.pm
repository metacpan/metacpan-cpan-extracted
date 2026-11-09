package DBIO::Informix::Diff::PrimaryKey;
# ABSTRACT: Diff operations for Informix primary keys

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Informix::Util qw(_quote_ident);

__PACKAGE__->mk_diff_accessors(qw(table_name constraint_name columns replaced));


sub _pk_columns {
  my ($cols) = @_;
  return [ map { $_->{column_name} }
    sort { ($a->{pk_position} // 0) <=> ($b->{pk_position} // 0) }
    grep { $_->{is_pk} } @{ $cols // [] } ];
}


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;
  $_ //= {} for $source_cols, $target_cols, $source_tables, $target_tables;

  my @ops;
  for my $table (sort keys %$source_tables) {
    next unless exists $target_tables->{$table};
    next if ($source_tables->{$table}{kind} // '') eq 'view'
         || ($target_tables->{$table}{kind} // '') eq 'view';

    my ($have, $want) = (_pk_columns($source_cols->{$table}), _pk_columns($target_cols->{$table}));
    next if join("\0", @$have) eq join("\0", @$want);

    push @ops, $class->new(action => 'drop', table_name => $table,
      constraint_name => $source_tables->{$table}{primary_key_name}, columns => $have,
      replaced => (@$want ? 1 : 0)) if @$have;
    push @ops, $class->new(action => 'add', table_name => $table, columns => $want) if @$want;
  }
  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $tbl = _quote_ident($self->table_name);

  if ($self->action eq 'drop') {
    my $name = $self->constraint_name;
    die sprintf "Informix primary key of table %s cannot be dropped: the model holds no name for it (primary_key_name of the table in the tables section)\n",
      $self->table_name unless defined $name && length $name;
    return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', $tbl, _quote_ident($name);
  }

  return sprintf 'ALTER TABLE %s ADD CONSTRAINT PRIMARY KEY (%s);', $tbl,
    join(', ', map { _quote_ident($_) } @{ $self->columns });
}


sub summary {
  my ($self) = @_;
  return sprintf '%s primary key: (%s) on %s', $self->summary_prefix,
    join(', ', @{ $self->columns }), $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Diff::PrimaryKey - Diff operations for Informix primary keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a primary key diff operation: C<ALTER TABLE ... ADD CONSTRAINT
PRIMARY KEY (...)> or C<ALTER TABLE ... DROP CONSTRAINT>.

The model has no section for primary keys. The key is read from C<is_pk> and
C<pk_position> of the columns, as the columns it covers in key order, and the
name from C<primary_key_name> of the table in the C<tables> section (the
server's C<u E<lt>tabidE<gt>_E<lt>nE<gt>> unless the table was created with a named one).
A key is compared by its columns in order -- the order is the one a foreign
key must reference it in (-297 otherwise) -- and a changed key is its old form
dropped and the new one added.

    ALTER TABLE t DROP CONSTRAINT u136_41;
    ALTER TABLE t ADD CONSTRAINT PRIMARY KEY (a, b);

Informix has no C<DROP PRIMARY KEY> and refuses a second key (-704), so the
old key is dropped first, by its name; a key to add is written without one,
the server names it. A model without C<primary_key_name> cannot drop a key:
C<as_sql> dies, naming the table. Views are skipped, and so are tables on one
side only: a new table has its key in its C<CREATE TABLE>, a dropped one takes
it along.

=head1 ATTRIBUTES

=head2 replaced

True for the C<drop> of a primary key that is the first half of a C<drop> +
C<add> of the key of that table with other columns: it replaces the key and
leaves the table with a key, so it counts as changing, not destructive (core
ADR 0080, L<DBIO::Diff::Base/destructive_operations>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::Informix::Diff::PrimaryKey->diff(
        $source_columns, $target_columns, $source_tables, $target_tables,
    );

The drops and the adds in table order; L<DBIO::Informix::Diff> places them
among the other operations.

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
