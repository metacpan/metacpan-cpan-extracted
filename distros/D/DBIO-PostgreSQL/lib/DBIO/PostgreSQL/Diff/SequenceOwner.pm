package DBIO::PostgreSQL::Diff::SequenceOwner;
# ABSTRACT: Diff operations for the column a PostgreSQL sequence belongs to

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Diff::Sequence ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_qualified);

__PACKAGE__->mk_diff_accessors(qw(schema_name sequence_name table_name column_name));






# The column an entry of the model says the sequence belongs to, as a list
# ( table, column ), or the empty list for none. The sequence of an identity
# column is no sequence of its own and is not asked.
sub _owner {
  my ($info) = @_;
  return unless DBIO::PostgreSQL::Diff::Sequence->is_own($info);
  my ($table, $column) = @{$info}{qw( owned_by_table_name owned_by_column )};
  return unless defined $table && defined $column;
  return ($table, $column);
}


sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  for my $key (sort keys %$target) {
    my $new = $target->{$key};
    next unless DBIO::PostgreSQL::Diff::Sequence->is_own($new);
    next unless exists $new->{owned_by_table_name};

    my @is  = _owner($new);
    my @was = _owner($source->{$key});
    next if @is == @was && !grep { $is[$_] ne $was[$_] } 0 .. $#is;

    my ($schema_name, $sequence_name)
      = DBIO::PostgreSQL::Introspect->key_names($key, sequence_name => $new);
    push @ops, $class->new(
      action        => 'own',
      schema_name   => $schema_name,
      sequence_name => $sequence_name,
      table_name    => $is[0],
      column_name   => $is[1],
    );
  }

  return @ops;
}


sub qualified_name {
  my ($self) = @_;
  return join '.', grep { defined } $self->schema_name, $self->sequence_name;
}


sub as_sql {
  my ($self) = @_;
  my $object = 'sequence ' . $self->qualified_name;

  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object)
    unless ($self->action // '') eq 'own';
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object, 'it has no sequence_name')
    unless length($self->sequence_name // '');

  my @column = grep { length($_ // '') } $self->table_name, $self->column_name;
  DBIO::PostgreSQL::Diff::NoStatement->throw(
    $self, $object, 'it names a table without a column or a column without a table',
  ) if @column == 1;

  my @schema = grep { defined } $self->schema_name;
  return sprintf 'ALTER SEQUENCE %s OWNED BY %s;',
    quote_qualified(@schema, $self->sequence_name),
    ( @column ? quote_qualified(@schema, @column) : 'NONE' );
}


sub summary {
  my ($self) = @_;
  my @column = grep { defined } $self->table_name, $self->column_name;
  return sprintf '  ~sequence: %s (owned by %s)', $self->qualified_name,
    ( @column ? join('.', grep { defined } $self->schema_name, @column) : 'none' );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::SequenceOwner - Diff operations for the column a PostgreSQL sequence belongs to

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents C<ALTER SEQUENCE ... OWNED BY>: the statement that gives a sequence
to a column, so that it goes when the column or its table goes, or takes it
from one (C<OWNED BY NONE>). Instances are produced by L</diff> and consumed
by L<DBIO::PostgreSQL::Diff>.

It reads the same C<sequences> section as L<DBIO::PostgreSQL::Diff::Sequence>
and is a class of its own because its statement has another place in the
order: a sequence is created ahead of the table whose default calls it, and
can be given to a column only when that column is there
(L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>). The C<action> of its
operations is C<own>.

=head1 ATTRIBUTES

=head2 schema_name

The schema the sequence is in -- and the table, where it belongs to one:
PostgreSQL gives a sequence to no table of another schema.

=head2 sequence_name

The name of the sequence.

=head2 table_name

The table whose column the sequence is to belong to. C<undef> where it is to
belong to none.

=head2 column_name

That column. C<undef> where the sequence is to belong to none.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::SequenceOwner->diff($source, $target);

Compares two C<sequences> sections and returns an C<own> operation for every
sequence of its own (L<DBIO::PostgreSQL::Diff::Sequence/is_own>) in the
target that belongs to another column there than in the source, or to one on
one side only -- and so for every sequence the diff creates that a column
owns in the target: a new sequence belongs to none.

What a sequence belongs to is read from C<owned_by_table_name> and
C<owned_by_column> (L<DBIO::PostgreSQL::Introspect::Sequences/fetch>). A
target entry without the key C<owned_by_table_name> -- a model built by hand
-- says nothing about it and asks for nothing.

A sequence the target takes from its column is taken ahead of the drops, so
one that stays while its table or column goes is not taken along.

=head2 qualified_name

    my $fqn = $op->qualified_name;  # 'public.t_id_seq'

The schema and the name of the sequence joined with a dot, unquoted: what
L</summary> prints. It is not SQL.

=head2 as_sql

Returns C<ALTER SEQUENCE ... OWNED BY schema.table.column> for an C<own>
operation with a table and a column, and C<ALTER SEQUENCE ... OWNED BY NONE>
for one with neither. Every name is written as an identifier by the server's
rule (L<DBIO::PostgreSQL::Util/quote_ident>); the table is written in the
schema of the sequence.

It dies (L<DBIO::PostgreSQL::Diff::NoStatement/throw>) for an C<action> this
class does not know, for a sequence without a name, and for an operation
that names a table and no column or a column and no table.

=head2 summary

Returns a one-line description such as C<~sequence: public.t_id_seq (owned by
public.t.id)>, or C<~sequence: public.t_id_seq (owned by none)>.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL::Diff::Sequence> - creates the sequence

=item * L<DBIO::PostgreSQL::Introspect::Sequences> - what the model holds of a sequence

=item * L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
