package DBIO::PostgreSQL::ResultSet;
# ABSTRACT: ResultSet with pgvector nearest-neighbor search

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::ResultSet';

use DBIO::PostgreSQL::Vector qw(vector);

# Distance keyword -> DBIO::PostgreSQL::Vector::Op method. The keyword set is
# the one the Rails "neighbor" gem uses, so a query ported from that ecosystem
# keeps its strings; the aliases (l2, l1) are the metric names pgvector's own
# documentation uses for the same operators.
my %DISTANCE_METHOD = (
  euclidean     => 'l2_distance',
  l2            => 'l2_distance',
  cosine        => 'cosine_distance',
  inner_product => 'max_inner_product',
  taxicab       => 'l1_distance',
  l1            => 'l1_distance',
  hamming       => 'hamming_distance',
  jaccard       => 'jaccard_distance',
);

my %KNOWN_OPTION = map { $_ => 1 } qw( distance rows cast );

sub nearest_neighbors {
  my ( $self, $column, $query_vector, %opts ) = @_;

  my @unknown = sort grep { !$KNOWN_OPTION{$_} } keys %opts;
  $self->throw_exception( 'nearest_neighbors: unknown option '
      . join( ', ', map { "'$_'" } @unknown )
      . ' (known: '
      . join( ', ', sort keys %KNOWN_OPTION )
      . '); chain ->search for everything else' )
    if @unknown;

  # Required on purpose: the metric is what has to match the operator class of
  # the index (see the OPERATOR CLASSES section), so it is never guessed here.
  $self->throw_exception( 'nearest_neighbors: distance is required (one of: '
      . join( ', ', sort keys %DISTANCE_METHOD )
      . ')' )
    unless defined $opts{distance} && length $opts{distance};

  my $method = $DISTANCE_METHOD{ lc $opts{distance} };
  $self->throw_exception( "nearest_neighbors: unknown distance '$opts{distance}' (known: "
      . join( ', ', sort keys %DISTANCE_METHOD )
      . ')' )
    unless $method;

  # An unqualified name belongs to this resultset's own source; a caller who
  # spelled out an alias (a joined source, or plain 'me.') keeps their string.
  my $col =
    index( $column, '.' ) >= 0
    ? $column
    : $self->current_source_alias . '.' . $column;

  my $op = vector( $col, ( defined $opts{cast} ? ( cast => $opts{cast} ) : () ) )
    ->$method($query_vector);

  return $self->search(
    undef,
    {
      order_by  => $op->as_order,
      '+select' => [ $op->as_select('neighbor_distance') ],
      '+as'     => ['neighbor_distance'],
      ( defined $opts{rows} ? ( rows => $opts{rows} ) : () ),
    },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::ResultSet - ResultSet with pgvector nearest-neighbor search

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');

  __PACKAGE__->table('items');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    name      => { data_type => 'text' },
    embedding => { data_type => 'vector(3)' },   # <- promotes resultset_class
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->pg_index('idx_items_embedding' => {
    using     => 'hnsw',
    columns   => ['embedding'],
    opclasses => { embedding => 'vector_cosine_ops' },
  });

  # ... elsewhere

  my $rs = $schema->resultset('Item')->nearest_neighbors(
    embedding => [ 0.1, 0.2, 0.3 ],
    distance  => 'cosine',
    rows      => 5,
  );
  # SELECT me.id, me.name, me.embedding, (me.embedding <=> ?::vector) AS neighbor_distance
  #   FROM items me
  #  ORDER BY (me.embedding <=> ?::vector)
  #  LIMIT ?

=head1 DESCRIPTION

A L<DBIO::ResultSet> subclass carrying pgvector query sugar, currently
L</nearest_neighbors>.

A source gets this class automatically: L<DBIO::PostgreSQL::Result> promotes
its C<resultset_class> the first time a column with a pgvector data type
(C<vector>, C<halfvec>, C<sparsevec>) is registered, so declaring the column is
the whole opt-in. The promotion is skipped when the source's C<resultset_class>
already inherits from this class, so a custom resultset survives:

  package MyApp::Schema::ResultSet::Item;
  use base 'DBIO::PostgreSQL::ResultSet';

  # ... your own methods, plus nearest_neighbors

Set it by hand for the cases auto-detection cannot see - a C<bit> column
queried with Hamming/Jaccard distance, or a result class that does not load
the C<PostgreSQL::Result> component:

  __PACKAGE__->resultset_class('DBIO::PostgreSQL::ResultSet');

=head1 METHODS

=head2 nearest_neighbors

  my $rs = $schema->resultset('Item')->nearest_neighbors(
    embedding => [ 0.1, 0.2, 0.3 ],
    distance  => 'cosine',
    rows      => 10,
  );

  while ( my $item = $rs->next ) {
    printf "%s (%.4f)\n", $item->name, $item->get_column('neighbor_distance');
  }

K-nearest-neighbor search on a pgvector column: orders by the distance between
the column and C<$query_vector> (nearest first) and selects that distance as
C<neighbor_distance>.

Arguments are the column, the query vector, and named options:

=over 4

=item * C<distance> - B<required>, the metric. See L</DISTANCE KEYWORDS>.

=item * C<rows> - optional row limit, the C<k> of "k nearest neighbors".

=item * C<cast> - optional placeholder cast for the query vector, passed
through to L<DBIO::PostgreSQL::Vector/vector>. Needed for C<halfvec> and
C<bit> columns; a C<sparsevec> query vector (hashref) casts itself.

=back

The column may be given unqualified (C<'embedding'>), in which case it is
resolved against this resultset's current source alias, or fully qualified
(C<'me.embedding'>, C<'items.embedding'>) to name a joined source.

The query vector is passed to
L<DBIO::PostgreSQL::Vector::Op> and travels as a bind parameter, so an
arrayref, a pgvector text string, or a sparsevec hashref all work.

The return value is an ordinary resultset, so it chains:

  $rs->nearest_neighbors( embedding => $v, distance => 'cosine' )
     ->search( { 'me.active' => 1 } )
     ->slice( 0, 9 );

An unknown option, a missing C<distance>, or an unknown distance keyword
throws a L<DBIO::Exception>.

This method is deliberately opinionated (it always selects
C<neighbor_distance>, it always orders ascending). For a query that needs
something else - the distance in C<WHERE>, a descending order, a different
alias - use L<DBIO::PostgreSQL::Vector/vector> directly; this method is sugar
over it, not a replacement.

=head1 DISTANCE KEYWORDS

  Keyword         Operator   Vector::Op method
  --------------------------------------------
  euclidean, l2   <->        l2_distance
  cosine          <=>        cosine_distance
  inner_product   <#>        max_inner_product
  taxicab, l1     <+>        l1_distance
  hamming         <~>        hamming_distance
  jaccard         <%>        jaccard_distance

Keywords are case-insensitive. The set is the Rails C<neighbor> gem's, plus
the C<l2>/C<l1> aliases.

C<inner_product> uses pgvector's C<<< <#> >>>, which returns the B<negative>
inner product - so ascending order still puts the most similar row first, and
C<neighbor_distance> is negative for positively-correlated vectors.

=head1 OPERATOR CLASSES

Which distance you ask for decides whether an index can serve the query. An
C<hnsw> or C<ivfflat> index only answers for the operator its operator class
was built for: C<vector_l2_ops> serves C<<< <-> >>>, C<vector_cosine_ops>
serves C<<< <=> >>>, C<vector_ip_ops> serves C<<< <#> >>> (with the
C<halfvec_*>, C<sparsevec_*> and C<bit_*> families for the other column
types). Ordering by an operator no index covers is B<not> an error -
PostgreSQL simply falls back to a sequential scan and computes every row's
distance.

C<nearest_neighbors> does not and cannot check this: nothing in a resultset
knows which indexes the database actually has. Declare the pairing where it
belongs, in C<opclasses> on the L<DBIO::PostgreSQL::Result/pg_index> that
covers the column, and pass the C<distance> that matches it. C<EXPLAIN> on the
generated query is the only real confirmation.

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::Vector> - the C<vector()> DSL this sugar is built on

=item * L<DBIO::PostgreSQL::Result> - promotes C<resultset_class> to this class, and declares the index with C<pg_index>

=item * L<DBIO::ResultSet> - the base class, for everything that is not pgvector

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
