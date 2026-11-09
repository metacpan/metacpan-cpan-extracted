package DBIO::PostgreSQL::Diff::Sequence;
# ABSTRACT: Diff operations for PostgreSQL sequences

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified);

__PACKAGE__->mk_diff_accessors(qw(schema_name sequence_name sequence_info));






sub is_own {
  my ($class, $info) = @_;
  return $info && !$info->{is_identity} ? 1 : 0;
}

sub _refuse_name_held_by_identity {
  my ($key, $old) = @_;
  my $schema = $old->{schema_name};
  my ($table, $column) = @{$old}{qw( owned_by_table_name owned_by_column )};

  my ($of, @way_out) = defined $schema && defined $table && defined $column
    ? ( 'of column ' . join('.', $schema, $table, $column),
        'Take the identity from the column yourself,',
        sprintf('  ALTER TABLE %s ALTER COLUMN %s DROP IDENTITY;',
          quote_qualified($schema, $table), quote_ident($column)),
        'and diff again: the diff then creates the sequence and makes of the column what',
        'the target has. The sequence it creates starts where the target has it start,',
        'not where the identity stood.' )
    : ( 'of a column',
        'Take the identity from that column yourself (ALTER TABLE ... ALTER COLUMN ...',
        'DROP IDENTITY) and diff again.' );

  die join "\n",
    "refusing to diff: sequence $key is a sequence of its own in the target, and in the database that name is the identity sequence $of",
    '',
    'The sequence of an identity column is a part of the column: DROP IDENTITY takes',
    'it and nothing else does, and until then CREATE SEQUENCE finds the name taken',
    '(relation already exists). The diff creates a sequence ahead of everything it',
    'does to a column. No statement was generated.',
    '',
    @way_out,
    '';
}


sub diff {
  my ($class, $source, $target, $source_schemas, $target_schemas) = @_;
  my @ops;

  for my $key (sort keys %$target) {
    my $new = $target->{$key};
    next unless $class->is_own($new);

    my $old = $source->{$key};
    next if $class->is_own($old);
    _refuse_name_held_by_identity($key, $old) if $old;

    my ($schema_name, $sequence_name)
      = DBIO::PostgreSQL::Introspect->key_names($key, sequence_name => $new);
    push @ops, $class->new(
      action        => 'create',
      schema_name   => $schema_name,
      sequence_name => $sequence_name,
      sequence_info => $new,
    );
  }

  # A schema is dropped without CASCADE: the sequences no column owns that
  # stand in it are dropped ahead of it. One a column owns goes with that
  # column's table, which the schema loses first.
  if ($source_schemas && $target_schemas) {
    for my $key (sort keys %$source) {
      my $old = $source->{$key};
      next unless $class->is_own($old) && !defined $old->{owned_by_table_name};
      next if exists $target->{$key};
      my $schema = $old->{schema_name};
      next unless defined $schema && exists $source_schemas->{$schema} && !exists $target_schemas->{$schema};
      push @ops, $class->new(
        action        => 'drop',
        schema_name   => $schema,
        sequence_name => $old->{sequence_name},
        sequence_info => $old,
      );
    }
  }

  return @ops;
}


sub qualified_name {
  my ($self) = @_;
  return join '.', grep { defined } $self->schema_name, $self->sequence_name;
}


# The parameters of CREATE SEQUENCE, in the order they are written, each with
# the key of the model that has its value.
my @PARAMETERS = (
  [ 'AS'           => 'data_type'   ],
  [ 'INCREMENT BY' => 'increment'   ],
  [ 'MINVALUE'     => 'min_value'   ],
  [ 'MAXVALUE'     => 'max_value'   ],
  [ 'START WITH'   => 'start_value' ],
  [ 'CACHE'        => 'cache_size'  ],
);

sub as_sql {
  my ($self) = @_;
  my $info   = $self->sequence_info // {};
  my $object = 'sequence ' . $self->qualified_name;

  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object)
    unless ($self->action // '') =~ /\A(?:create|drop)\z/;
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object, 'it has no sequence_name')
    unless length($self->sequence_name // '');

  return 'DROP SEQUENCE ' . quote_qualified(grep { defined } $self->schema_name, $self->sequence_name) . ';'
    if $self->action eq 'drop';

  return join(' ',
    'CREATE SEQUENCE',
    quote_qualified(grep { defined } $self->schema_name, $self->sequence_name),
    ( map { "$_->[0] $info->{ $_->[1] }" }
      grep { length($info->{ $_->[1] } // '') } @PARAMETERS ),
    ( defined $info->{is_cycle} ? ( $info->{is_cycle} ? 'CYCLE' : 'NO CYCLE' ) : () ),
  ) . ';';
}


sub summary {
  my ($self) = @_;
  return sprintf '  %ssequence: %s', $self->summary_prefix, $self->qualified_name;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Sequence - Diff operations for PostgreSQL sequences

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents the sequence operations the diff has: C<CREATE SEQUENCE> for a
sequence the target has and the database lacks, and C<DROP SEQUENCE> for a
sequence no column owns that stands in a schema the diff drops. Instances are produced by
L</diff> and consumed by L<DBIO::PostgreSQL::Diff>.

It is here for the columns that count from a sequence. A C<serial> column is,
in the catalog, a column with the default C<nextval('t_id_seq'::regclass)>
and a sequence the column owns, and the diff writes a column as the catalog
has it: C<CREATE TABLE>, C<ADD COLUMN> and C<SET DEFAULT> all name the
sequence, and PostgreSQL takes none of them before the sequence is there
(C<relation "t_id_seq" does not exist>). So the sequence is created first,
ahead of every table and column (L<DBIO::PostgreSQL::Diff/ORDER OF
OPERATIONS>), and tied to its column once that is there
(L<DBIO::PostgreSQL::Diff::SequenceOwner>) -- three statements where the
install script has the one word C<serial>:

    CREATE SEQUENCE public.t_id_seq AS integer INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1 NO CYCLE;
    CREATE TABLE public.t (id integer NOT NULL DEFAULT nextval('t_id_seq'::regclass));
    ALTER SEQUENCE public.t_id_seq OWNED BY public.t.id;

The diff does not write C<serial> back. C<serial> picks the name of the
sequence itself, a number behind it where the name is taken and a shorter
one where table and column are long; it cannot be given to a column that is
there; and it says nothing of a sequence that counts otherwise. The three
statements make what the target has, under the name the default calls, and
are what the same sequence needs when no column owns it.

=head2 What is not done

A sequence is created, and given to its column, and nothing else:

=over 4

=item * A sequence only the database has is left where it is. The one a
column owns goes with that column -- C<DROP COLUMN> and C<DROP TABLE> take
it -- and one whose column loses its default (C<serial> made a plain
C<integer>, or an identity column) stays behind, owned by the column and called
by nothing. The one exception is a sequence no column owns in a schema that is
dropped (L</diff>): C<DROP SCHEMA> is written without C<CASCADE>, so it would
find the sequence in the schema.

=item * A sequence both sides have is not compared: another type (C<serial>
made C<bigserial> alters the column and leaves its sequence counting in
C<integer>), another increment, bounds, cache or cycle are not seen, and no
C<ALTER SEQUENCE> is written for them. Only what it belongs to is
(L<DBIO::PostgreSQL::Diff::SequenceOwner>).

=item * Where a sequence stands is data and not in the model. One the diff
creates starts at its C<start_value>, also when it is for a column of a table
that has rows: C<ADD COLUMN> numbers those rows from it, C<SET DEFAULT> on a
column that is there does not, and the next row counts from the start.

=back

The sequence of an identity column is none of this class's: it is a part of
its column (L<DBIO::PostgreSQL::Introspect::Sequences>, C<is_identity>), made
by C<GENERATED ... AS IDENTITY> as L<DBIO::PostgreSQL::Diff::Table> and
L<DBIO::PostgreSQL::Diff::Column> write it.

=head1 ATTRIBUTES

=head2 schema_name

The schema the sequence is in.

=head2 sequence_name

The name of the sequence.

=head2 sequence_info

The target's entry for the sequence
(L<DBIO::PostgreSQL::Introspect::Sequences/fetch>): what it counts in and how.

=head1 METHODS

=head2 is_own

    next unless DBIO::PostgreSQL::Diff::Sequence->is_own($entry);

True for an entry of the C<sequences> section that is a sequence of its own,
false for the sequence of an identity column (C<is_identity>), which is a
part of that column, and for no entry at all.

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Sequence->diff(
      $source, $target, $source_schemas, $target_schemas);

Compares two C<sequences> sections (as from
L<DBIO::PostgreSQL::Introspect::Sequences>) and returns a C<create> operation
for every sequence of its own (L</is_own>) that the target has and the source
lacks, in the order of their keys. Nothing is returned for a sequence both
have, or for one only the source has: see L</What is not done>, except that a
sequence of its own (L</is_own>) that no column owns and that stands in a
schema the source has and the target lacks (the optional C<schemas> sections of
the two models) gets a C<drop>, since the schema goes without C<CASCADE>.

One case is B<refused>, with C<refusing to diff: ...> and no statement: a
sequence to create whose name the database has as the sequence of an identity
column -- what a column that was C<GENERATED ... AS IDENTITY> and is declared
C<serial> now comes to, since both name their sequence C<< <table>_<column>_seq >>.
C<CREATE SEQUENCE> finds the name taken until C<DROP IDENTITY> has run, and
that is a statement for the column, which comes later. The message names the
sequence and the column and the way out, C<ALTER TABLE ... ALTER COLUMN ...
DROP IDENTITY>.

=head2 qualified_name

    my $fqn = $op->qualified_name;  # 'public.t_id_seq'

The schema and the name joined with a dot, unquoted: what L</summary> prints.
It is not SQL.

=head2 as_sql

Returns C<DROP SEQUENCE> for a C<drop>, and C<CREATE SEQUENCE> for a C<create>, with every parameter the
C<sequence_info> has: C<AS> its C<data_type>, C<INCREMENT BY>, C<MINVALUE>,
C<MAXVALUE>, C<START WITH>, C<CACHE>, and C<CYCLE> or C<NO CYCLE>. A model
read from the catalog has them all, so the sequence is made as the target has
it whatever the server's defaults are; one built by hand that leaves a
parameter out gets the server's default for it. Schema and name are written
as identifiers by the server's rule (L<DBIO::PostgreSQL::Util/quote_ident>),
the parameters as given.

For an C<action> this class does not know it dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>), and for a sequence without a
name.

=head2 summary

Returns a one-line description such as C<+sequence: public.t_id_seq>, or
C<-sequence: ...> for a drop.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL::Diff::SequenceOwner> - gives a sequence to its column

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
