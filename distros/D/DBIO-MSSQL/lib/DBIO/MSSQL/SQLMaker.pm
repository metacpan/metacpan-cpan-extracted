package DBIO::MSSQL::SQLMaker;
# ABSTRACT: MSSQL-specific SQL generation for DBIO

use warnings;

our $VERSION = '0.900004';

use strict;

use base qw( DBIO::SQLMaker );



sub new {
  my $self = shift->next::method(@_);

  # copy first: the table of render ops may be shared with other makers
  $self->{render_op} = {
    %{ $self->{render_op} },
    nulls_first => '_render_op_nulls',
    nulls_last  => '_render_op_nulls',
  };

  return $self;
}


sub _render_op_nulls {
  my ($self, $op, $args) = @_;
  my ($node) = @$args;

  return $self->join_query_parts(', ',
    $self->_render_nulls_key($op, $node),
    $node,
  );
}


sub _chunkify_order_by {
  my ($self, $expanded) = @_;

  if (ref $expanded eq 'HASH' and ref $expanded->{-op} eq 'ARRAY'
      and $expanded->{-op}[0] =~ /\Anulls_(?:first|last)\z/) {
    my ($op, $node) = @{ $expanded->{-op} };
    return (
      $self->_render_nulls_key($op, $node),
      $self->_chunkify_order_by($node),
    );
  }

  return $self->next::method($expanded);
}


sub _nulls_expr {
  my ($self, $node) = @_;
  return $node->{-op}[1]
    if ref $node eq 'HASH' and ref $node->{-op} eq 'ARRAY'
      and $node->{-op}[0] =~ /\A(?:asc|desc)\z/;
  return $node;
}


sub _render_nulls_key {
  my ($self, $op, $node) = @_;
  my $then_else = $op eq 'nulls_first' ? 'THEN 0 ELSE 1 END' : 'THEN 1 ELSE 0 END';
  return $self->join_query_parts(' ',
    'CASE WHEN', { -op => [ 'is_null', $self->_nulls_expr($node) ] }, "$then_else ASC",
  );
}


sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
  return $self->_RowNumberOver($sql, $rs_attrs, $rows, $offset);
}

#
# MSSQL does not support ... OVER() ... RNO limits
#
sub _rno_default_order {
  return \ '(SELECT(1))';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::SQLMaker - MSSQL-specific SQL generation for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for Microsoft SQL Server. Implements LIMIT/OFFSET
via C<ROW_NUMBER() OVER()> (the dialect SQL Server 2005+ supports) and
overrides the default C<OVER()> order expression to use C<(SELECT(1))>
because MSSQL does not support an empty C<OVER()> clause.

Used automatically by L<DBIO::MSSQL::Storage>.

=head1 METHODS

=head2 _render_op_nulls

Renders the C<nulls_first> / C<nulls_last> ops SQL::Abstract builds for
C<-nulls> as C<< CASE WHEN expr IS NULL THEN 0|1 ELSE 1|0 END ASC, expr
[ASC|DESC] >>. The wrapped node is the sort entry C<< expr ASC|DESC >> (or a
bare C<expr>).

=head2 _chunkify_order_by

The limit dialect (C<ROW_NUMBER() OVER()>) takes the C<order_by> apart in
chunks, one per sort key, to select the order criteria into the inner query and
to re-alias them in the C<OVER (ORDER BY ...)>. A C<-nulls> entry is two sort
keys here, so it is two chunks: the C<CASE WHEN expr IS NULL ...> key
(C<ASC>) and the entry itself. As one chunk the comma inside it would end up in
a select list as C<CASE ... ASC, col AS ORDER__BY__001>. In the limited query
the keys appear as C<ORDER__BY__001>, C<ORDER__BY__002> in the C<OVER> clause,
each selected in the inner query.

=head2 _nulls_expr

The expression of a sort entry C<< expr ASC|DESC >> (or a bare C<expr>).

=head2 _render_nulls_key

Renders the leading sort key, C<< CASE WHEN expr IS NULL THEN 0|1 ELSE 1|0 END
ASC >>.

=head2 apply_limit

    my $sql = $sqlmaker->apply_limit($sql, $rs_attrs, $rows, $offset);

MSSQL has no C<LIMIT>/C<OFFSET> keyword (before 2012's C<OFFSET ... FETCH>).
DBIO targets the broadly compatible C<ROW_NUMBER() OVER()> windowing
dialect: the query is wrapped in a derived table that numbers rows, then
sliced by C<WHERE rno BETWEEN offset+1 AND offset+rows>. Replaces the
DBIx::Class C<sql_limit_dialect> string dispatch.

=head1 NULLS FIRST / NULLS LAST

SQL Server has no C<NULLS FIRST> / C<NULLS LAST>; the C<-nulls> key of an
C<order_by> entry is emulated. The sort key is preceded by a sort on whether it
is C<NULL>: C<< { -desc => 'col', -nulls => 'first' } >> renders
C<< CASE WHEN [col] IS NULL THEN 0 ELSE 1 END ASC, [col] DESC >>, and
C<< -nulls => 'last' >> renders
C<< CASE WHEN [col] IS NULL THEN 1 ELSE 0 END ASC, [col] DESC >> -- the rows
come back in the same order as on PostgreSQL. The leading key is always
C<ASC>, whatever the direction of the column. It is also in the
C<OVER (ORDER BY ...)> of the C<ROW_NUMBER()> limit (this dialect builds no
reversed middle or outer order) and in the order of a prefetch subquery. The column expression is rendered twice, so a bind inside
it is bound twice, in order. There is no C<TOP> limit dialect in this driver;
the only C<TOP> is the one that makes an ordered subselect legal
(L<DBIO::MSSQL::Storage/ORDERED SUBSELECTS>), which keeps the order_by as it
is. See L</_render_op_nulls>.

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL::Storage> - MSSQL storage (uses this SQL maker)

=item * L<DBIO::SQLMaker> - Base SQL maker class

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
