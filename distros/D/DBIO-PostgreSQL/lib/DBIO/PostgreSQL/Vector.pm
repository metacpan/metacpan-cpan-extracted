package DBIO::PostgreSQL::Vector;
# ABSTRACT: pgvector distance-query helpers for DBIO::PostgreSQL

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Vector::Op ();

use Exporter 'import';
our @EXPORT_OK = qw(vector);

sub vector {
  my ( $col, %opts ) = @_;
  return DBIO::PostgreSQL::Vector::Op->new( col => $col, %opts );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Vector - pgvector distance-query helpers for DBIO::PostgreSQL

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::PostgreSQL::Vector qw(vector);

  # KNN — nearest neighbors by cosine distance (smallest first)
  $rs->search(
    {},
    {
      order_by => vector('me.embedding')->cosine_distance([0.1, 0.2])->as_order,
      rows     => 5,
    },
  );
  # ORDER BY (me.embedding <=> ?::vector) LIMIT 5

  # KNN, descending (furthest first)
  $rs->search( {}, { order_by => { -desc => vector('me.embedding')->l2_distance([0.1, 0.2])->as_order } } );

  # Distance range filter in WHERE
  $rs->search( vector('me.embedding')->l2_distance($v)->lt(5) );
  # WHERE (me.embedding <-> ?::vector) < ?

  # Distance range filter combined with a regular condition
  $rs->search([
    vector('me.embedding')->l2_distance($v)->le(3),
    { 'me.active' => 1 },
  ]);

  # Selecting the distance (feeds the nearest_neighbors follow-up work)
  $rs->search(
    {},
    {
      select => [ vector('me.embedding')->l2_distance($v)->as_select('distance') ],
    },
  );
  # SELECT (me.embedding <-> ?::vector) AS distance

=head1 DESCRIPTION

Provides the C<vector()> helper function that builds pgvector distance
expressions without handwritten literal SQL. The generated SQL uses PostgreSQL's
pgvector distance operators (C<<< <-> >>>, C<<< <=> >>>, C<<< <#> >>>, C<<< <+> >>>
C<<< <~> >>>, C<<< <%> >>>) with the query vector as a bound parameter:

  ORDER BY (me.embedding <=> ?::vector)   -- cosine nearest neighbors (KNN)
  WHERE (me.embedding <-> ?::vector) < ?  -- L2 distance range filter

The distance methods themselves live on L<DBIO::PostgreSQL::Vector::Op>, the
operator object returned by C<vector()>. This module only exports the helper.

=head1 METHODS

=head2 vector

  use DBIO::PostgreSQL::Vector qw(vector);

  my $expr = vector($column);
  my $expr = vector($column, cast => 'halfvec');

Returns a L<DBIO::PostgreSQL::Vector::Op> object representing a vector column
ready for a distance operator. Call a distance method (C<l2_distance>,
C<cosine_distance>, ...) on the returned object to produce an expression for
ORDER BY, WHERE, or SELECT.

C<$column> may include a table alias prefix (e.g. C<'me.embedding'>). It is
code, written into the SQL as it is: letters, digits, underscores and dots,
and any other form throws a L<DBIO::Exception>. Do not build it from user
input.

The query vector is sent as a bind placeholder cast to the column's type.
C<cast> defaults to C<vector> and can be overridden for C<halfvec>,
C<sparsevec> or C<bit> columns — see L<DBIO::PostgreSQL::Vector::Op> for the
exact cast rules.

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::Vector::Op> — operator object returned by C<vector()>, with the distance and consumption methods

=item * L<DBIO::PostgreSQL::JSONB> — the JSONB path DSL this module mirrors

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
