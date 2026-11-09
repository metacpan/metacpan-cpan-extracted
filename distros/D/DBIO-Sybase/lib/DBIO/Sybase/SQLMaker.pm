package DBIO::Sybase::SQLMaker;
# ABSTRACT: Sybase ASE-specific SQL generation for DBIO

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


sub _order_by_chunks {
  my $self = shift;
  local $self->{_sybase_nulls_chunking} = 1;
  return $self->next::method(@_);
}


sub _render_op_nulls {
  my ($self, $op, $args) = @_;
  my ($node) = @$args;

  return $self->_render_unop_postfix($op, $args)
    if $self->{_sybase_nulls_chunking};

  my $expr = $node;
  if (ref $node eq 'HASH' and ref $node->{-op} eq 'ARRAY'
      and $node->{-op}[0] =~ /\A(?:asc|desc)\z/) {
    $expr = $node->{-op}[1];
  }

  my ($null, $other) = $op eq 'nulls_first' ? (0, 1) : (1, 0);

  return $self->join_query_parts(', ',
    $self->join_query_parts(' ',
      'CASE WHEN', { -op => [ 'is_null', $expr ] },
      "THEN $null ELSE $other END",
    ),
    $node,
  );
}


sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
  return $self->_GenericSubQ($sql, $rs_attrs, $rows, $offset);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::SQLMaker - Sybase ASE-specific SQL generation for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for Sybase ASE (Adaptive Server Enterprise).
ASE has no native C<LIMIT>/C<OFFSET> keyword, so this class overrides
L</apply_limit> to emit ASE-valid pagination.

Used automatically by L<DBIO::Sybase::Storage::ASE>.

C<NULLS FIRST> / C<NULLS LAST> (the C<-nulls> key of an C<order_by> entry) is
emulated, ASE has no such clause. The sort key is preceded by a sort on a
C<CASE> that tells the NULLs from the rest: C<< { -asc => 'col', -nulls =>
'first' } >> renders C<< CASE WHEN col IS NULL THEN 0 ELSE 1 END, col ASC >>,
and C<< -nulls => 'last' >> renders C<< CASE WHEN col IS NULL THEN 1 ELSE 0
END, col ASC >> -- the rows come back in the same order as on PostgreSQL, for
C<-desc> too. The column expression is rendered twice, so a bind inside it is
bound twice, in order. See L</_render_op_nulls>.

=head1 METHODS

=head2 _order_by_chunks

The limit dialects (L<DBIO::SQLMaker::ClassicExtensions/_GenericSubQ>) take the
rendered chunks of an C<order_by> apart as strings, looking for C<ASC|DESC
[NULLS FIRST|LAST]> at the end of each. The emulation is a prefix and would
leave them nothing to read, so while chunks are taken the ops render as SQL::Abstract
does, C<< expr ASC NULLS FIRST >>; the dialect then builds its own C<order_by>
from the parts and that one is rendered, with the emulation, by
L</_render_op_nulls>. Nothing of the standard form reaches the statement.

=head2 _render_op_nulls

Renders the C<nulls_first> / C<nulls_last> ops SQL::Abstract builds for
C<-nulls> as C<< CASE WHEN expr IS NULL THEN a ELSE b END, expr [ASC|DESC] >>.
The wrapped node is the sort entry C<< expr ASC|DESC >> (or a bare C<expr>);
the leading C<CASE> is 0 for a NULL and 1 for any other value to put the NULLs
first, the other way round to put them last.

=head2 apply_limit

    my $sql = $sqlmaker->apply_limit($sql, $rs_attrs, $rows, $offset);

ASE has no C<LIMIT>/C<OFFSET> keyword. DBIO targets the database-agnostic
C<GenericSubQ> dialect: the query is sliced by a correlated
C<WHERE ( SELECT COUNT(*) ... ) BETWEEN ? AND ?> subquery against a stable,
main-table-based order. This is the same dialect DBIx::Class used for ASE,
because ASE has no single windowing/C<TOP> construct that works reliably for
all query shapes across server versions. Replaces the DBIx::Class
C<sql_limit_dialect> string dispatch.

The C<rows>-only case (no offset) never reaches this method: it is handled
earlier by L<DBIO::Sybase::Storage::ASE/_prep_for_execute> via
C<SET ROWCOUNT>, which strips the limit before this SQLMaker runs.

GenericSubQ requires a stable, main-table-based C<order_by>; a resultset with
an offset but no such order raises an exception (this is intentional, see
L<DBIO::SQLMaker::ClassicExtensions/_GenericSubQ>).

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase::Storage::ASE> - Sybase ASE storage (uses this SQL maker)

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
