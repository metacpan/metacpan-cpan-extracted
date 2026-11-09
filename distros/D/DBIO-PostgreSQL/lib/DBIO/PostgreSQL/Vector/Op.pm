package DBIO::PostgreSQL::Vector::Op;
# ABSTRACT: pgvector distance-operator object built by vector()

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();

use DBIO::Exception ();



sub new {
  my ( $class, %args ) = @_;
  DBIO::Exception->throw(
    'vector: the column is a plain identifier (letters, digits, underscores and dots)'
  ) unless defined $args{col} && !ref $args{col} && $args{col} =~ /\A[\w.]+\z/;
  return bless \%args, $class;
}

# Only pgvector's real type names are legal cast targets. The cast is
# interpolated unquoted into the SQL string below, so anything outside this
# list is a SQL-injection surface, not a feature.
my %ALLOWED_CAST = map { $_ => 1 } qw( vector halfvec sparsevec bit );

# Builds the distance expression (col <op> ?::cast) and its bind from a query
# vector. Returns a fresh Op so the original (column-only) object stays reusable.
sub _distance {
  my ( $self, $op, $qv, $force_cast ) = @_;

  my $text = $self->_serialize_query_vector($qv);
  # Placeholder cast defaults to the vector type; a sparsevec query vector
  # (hashref) defaults to sparsevec instead. An explicit cast option on
  # vector() overrides either — the escape hatch for halfvec/sparsevec/bit.
  # hamming/jaccard force 'bit': their operators only exist for bit columns,
  # so any other cast (explicit or default) would be invalid SQL.
  # (The cast-override decision itself belongs to the pgvector ADR, karr k42.)
  my $cast = $self->{cast};
  DBIO::Exception->throw( 'vector: unknown cast '
      . "'$cast'"
      . ' (known: '
      . join( ', ', sort keys %ALLOWED_CAST )
      . ')' )
    if defined $cast && !$ALLOWED_CAST{$cast};
  $cast = $force_cast if defined $force_cast;
  $cast //= ( ref $qv eq 'HASH' ? 'sparsevec' : 'vector' );
  my $sql  = sprintf( '(%s %s ?::%s)', $self->{col}, $op, $cast );

  return bless { col => $self->{col}, sql => $sql, bind => [$text] }, ref $self;
}

sub l2_distance { $_[0]->_distance( '<->', $_[1] ) }


sub max_inner_product { $_[0]->_distance( '<#>', $_[1] ) }


sub cosine_distance { $_[0]->_distance( '<=>', $_[1] ) }


sub l1_distance { $_[0]->_distance( '<+>', $_[1] ) }


sub hamming_distance { $_[0]->_distance( '<~>', $_[1], 'bit' ) }


sub jaccard_distance { $_[0]->_distance( '<%>', $_[1], 'bit' ) }


# Serializes a query vector into pgvector's text input format.
#   arrayref              -> "[0.1,0.2]"
#   hashref (sparsevec)   -> "{i:v,...}/dims"
#   plain string          -> passed through verbatim
sub _serialize_query_vector {
  my ( $self, $qv ) = @_;

  if ( ref $qv eq 'ARRAY' ) {
    return '[' . join( ',', @$qv ) . ']';
  }

  if ( ref $qv eq 'HASH' ) {
    Carp::croak(
      'sparsevec query vector must be { dims => N, values => { idx => val } }'
    ) unless $qv->{dims} && ref $qv->{values} eq 'HASH';

    my $body = join( ',',
      map { "$_:$qv->{values}{$_}" } sort { $a <=> $b } keys %{ $qv->{values} } );
    return "{$body}/$qv->{dims}";
  }

  # plain string: caller is responsible for pgvector text syntax
  return $qv;
}

sub _require_distance {
  my ($self) = @_;
  Carp::croak(
    'no distance operator selected — call a distance method (l2_distance etc.) first'
  ) unless $self->{sql};
}

sub _op {
  my ( $self, $op, $val ) = @_;
  $self->_require_distance;
  return \[ sprintf( '%s %s ?', $self->{sql}, $op ), @{ $self->{bind} }, $val ];
}

sub lt { $_[0]->_op( '<', $_[1] ) }


sub le { $_[0]->_op( '<=', $_[1] ) }


sub gt { $_[0]->_op( '>', $_[1] ) }


sub ge { $_[0]->_op( '>=', $_[1] ) }


sub as_order {
  my ($self) = @_;
  $self->_require_distance;
  return \[ $self->{sql}, @{ $self->{bind} } ];
}


sub as_select {
  my ( $self, $alias ) = @_;
  $self->_require_distance;
  DBIO::Exception->throw(
    'vector: the alias of as_select is a plain identifier (letters, digits, underscores and dots)'
  ) unless defined $alias && !ref $alias && $alias =~ /\A[\w.]+\z/;
  return \[ sprintf( '%s AS %s',$self->{sql}, $alias ), @{ $self->{bind} } ];
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Vector::Op - pgvector distance-operator object built by vector()

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Operator object representing a pgvector distance expression. You do not
construct this class directly — use the C<vector()> helper from
L<DBIO::PostgreSQL::Vector>:

  use DBIO::PostgreSQL::Vector qw(vector);

  my $expr = vector('me.embedding');               # DBIO::PostgreSQL::Vector::Op
  $rs->search( {}, { order_by => $expr->cosine_distance([0.1, 0.2])->as_order } );

A distance method (C<l2_distance> etc.) selects the pgvector distance operator
and the query vector; it returns a fresh operator object carrying the rendered
SQL and its bind. A consumption method (C<as_order>, the threshold comparisons,
C<as_select>) then turns that into a SQL::Abstract fragment.

=head1 METHODS

=head2 new

  my $expr = DBIO::PostgreSQL::Vector::Op->new( col => 'me.embedding', cast => 'halfvec' );

The constructor C<vector()> calls. C<col> is the column as it is written into
the SQL; C<cast>, optional, the type the placeholder of the query vector is
cast to. The identifiers of this DSL are code: C<col> is letters, digits,
underscores and dots (C<me.embedding>), and any other form throws a
L<DBIO::Exception>. A C<cast> other than C<vector>, C<halfvec>,
C<sparsevec> and C<bit> throws when a distance method renders the expression.

=head2 l2_distance

  vector('me.embedding')->l2_distance([0.1, 0.2])
  # (me.embedding <-> ?::vector)

Euclidean (L2) distance, operator C<<< <-> >>>. Also the default "distance"
operator for most pgvector types.

=head2 max_inner_product

  vector('me.embedding')->max_inner_product([0.1, 0.2])
  # (me.embedding <#> ?::vector)

Maximum inner product, operator C<<< <#> >>>. Sort ascending for similarity
(the largest inner product sorts first).

=head2 cosine_distance

  vector('me.embedding')->cosine_distance([0.1, 0.2])
  # (me.embedding <=> ?::vector)

Cosine distance, operator C<<< <=> >>>. The standard choice for KNN search.

=head2 l1_distance

  vector('me.embedding')->l1_distance([0.1, 0.2])
  # (me.embedding <+> ?::vector)

Taxicab (Manhattan, L1) distance, operator C<<< <+> >>>. Requires the halfvec
type.

=head2 hamming_distance

  vector('me.embedding')->hamming_distance('101010')
  # (me.embedding <~> ?::bit)

Hamming distance, operator C<<< <~> >>>. For bit columns; the placeholder
cast is forced to C<bit> — the operator only exists for bit columns.

=head2 jaccard_distance

  vector('me.embedding')->jaccard_distance('101010')
  # (me.embedding <%> ?::bit)

Jaccard distance, operator C<<< <%> >>>. For bit columns; the placeholder
cast is forced to C<bit> — the operator only exists for bit columns.

=head2 lt

  vector('me.embedding')->l2_distance($v)->lt(5)
  # WHERE (me.embedding <-> ?::vector) < ?

Distance-range comparison: the expression holds if the distance is less than
C<$val>. Use for threshold filtering in C<search()>.

=head2 le

  vector('me.embedding')->l2_distance($v)->le(5)
  # WHERE (me.embedding <-> ?::vector) <= ?

=head2 gt

  vector('me.embedding')->l2_distance($v)->gt(5)
  # WHERE (me.embedding <-> ?::vector) > ?

=head2 ge

  vector('me.embedding')->l2_distance($v)->ge(5)
  # WHERE (me.embedding <-> ?::vector) >= ?

=head2 as_order

  $rs->search(
    {},
    { order_by => vector('me.embedding')->cosine_distance([0.1, 0.2])->as_order },
  );
  # ORDER BY (me.embedding <=> ?::vector)

Returns a literal-with-bind fragment suitable for use as an C<order_by> value
(the query vector travels as a bind placeholder, not inlined SQL). Combine with
C<-asc>/C<-desc> wrappers as usual:

  { order_by => { -desc => vector('me.embedding')->l2_distance($v)->as_order } }
  # ORDER BY (me.embedding <-> ?::vector) DESC

=head2 as_select

  $rs->search(
    {},
    { select => [ vector('me.embedding')->l2_distance($v)->as_select('distance') ] },
  );
  # SELECT (me.embedding <-> ?::vector) AS distance

Returns a literal-with-bind fragment selecting the distance value under the
given alias. C<$alias> is code, written into the SQL as it is: letters, digits,
underscores and dots, and any other form throws a L<DBIO::Exception>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::Vector> — the C<vector()> helper that builds these objects

=item * L<DBIO::PostgreSQL::JSONB::Op> — the JSONB operator object this class mirrors

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
