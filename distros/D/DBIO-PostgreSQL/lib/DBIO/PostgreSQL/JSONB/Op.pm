package DBIO::PostgreSQL::JSONB::Op;
# ABSTRACT: JSONB path-extraction operator object built by jsonb()

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();
use DBIO::Exception ();



sub new {
  my ( $class, %args ) = @_;
  DBIO::Exception->throw(
    'jsonb: the column is a plain identifier (letters, digits, underscores and dots)'
  ) unless defined $args{col} && !ref $args{col} && $args{col} =~ /\A[\w.]+\z/;
  return bless \%args, $class;
}

# Returns the SQL text-extraction expression -- (col->>?) or (col#>>?::text[])
# -- and the one bind it carries: the path element, or the path as the text
# of a text[] literal.
sub _text_sql {
  my ($self) = @_;

  my $col  = $self->{col};
  my @path = @{ $self->{path} };

  Carp::croak('jsonb() requires at least one path element') unless @path;

  return ( sprintf( '(%s->>?)', $col ), $path[0] ) if @path == 1;

  my $array = '{' . join( ',', map { ( my $k = $_ ) =~ s/([\\"])/\\$1/g; "\"$k\"" } @path ) . '}';
  return ( sprintf( '(%s#>>?::text[])', $col ), $array );
}

sub _op {
  my ( $self, $op, $val ) = @_;
  my ( $sql, @bind ) = $self->_text_sql;
  return \[ sprintf( '%s %s ?', $sql, $op ), @bind, $val ];
}

sub eq    { $_[0]->_op( '=',     $_[1] ) }


sub ne    { $_[0]->_op( '!=',    $_[1] ) }


sub lt    { $_[0]->_op( '<',     $_[1] ) }


sub le    { $_[0]->_op( '<=',    $_[1] ) }


sub gt    { $_[0]->_op( '>',     $_[1] ) }


sub ge    { $_[0]->_op( '>=',    $_[1] ) }


sub like  { $_[0]->_op( 'LIKE',  $_[1] ) }


sub ilike { $_[0]->_op( 'ILIKE', $_[1] ) }


sub is_null {
  my ($self) = @_;
  my ( $sql, @bind ) = $self->_text_sql;
  return \[ "$sql IS NULL", @bind ];
}


sub is_not_null {
  my ($self) = @_;
  my ( $sql, @bind ) = $self->_text_sql;
  return \[ "$sql IS NOT NULL", @bind ];
}


sub as_order {
  my ($self) = @_;
  my ( $sql, @bind ) = $self->_text_sql;
  return \[ $sql, @bind ];
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::JSONB::Op - JSONB path-extraction operator object built by jsonb()

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Operator object representing a text-extraction path into a PostgreSQL JSONB
column. You do not construct this class directly — use the C<jsonb()> helper
from L<DBIO::PostgreSQL::JSONB>:

  use DBIO::PostgreSQL::JSONB qw(jsonb);

  my $expr = jsonb('me.data', 'status');   # DBIO::PostgreSQL::JSONB::Op
  $rs->search( $expr->eq('active') );      # WHERE (me.data->>'status') = ?

Each comparison method returns a SQL::Abstract literal-with-bind fragment
suitable for passing to C<search()>.

=head1 METHODS

=head2 new

  my $expr = DBIO::PostgreSQL::JSONB::Op->new( col => 'me.data', path => ['status'] );

The constructor C<jsonb()> calls. C<col> is the column as it is written into
the SQL, C<path> an ArrayRef of the path elements. The identifiers of this DSL
are code: C<col> is letters, digits, underscores and dots (C<me.data>), and any
other form throws a L<DBIO::Exception>. The path elements are data: each
travels as a bind. A C<path> without an element croaks when a method renders
the expression.

=head2 eq

  jsonb('me.data', 'status')->eq('active')
  # WHERE (me.data->>?) = ?

=head2 ne

  jsonb('me.data', 'status')->ne('deleted')
  # WHERE (me.data->>?) != ?

=head2 lt

  jsonb('me.stats', 'score')->lt(50)
  # WHERE (me.stats->>?) < ?

=head2 le

  jsonb('me.stats', 'score')->le(100)
  # WHERE (me.stats->>?) <= ?

=head2 gt

  jsonb('me.stats', 'score')->gt(100)
  # WHERE (me.stats->>?) > ?

=head2 ge

  jsonb('me.stats', 'score')->ge(100)
  # WHERE (me.stats->>?) >= ?

=head2 like

  jsonb('me.data', 'name')->like('John%')
  # WHERE (me.data->>?) LIKE ?

=head2 ilike

  jsonb('me.data', 'name')->ilike('%smith%')
  # WHERE (me.data->>?) ILIKE ?

=head2 is_null

  jsonb('me.data', 'avatar')->is_null
  # WHERE (me.data->>?) IS NULL

Returns a condition fragment that checks whether the path resolves to SQL
NULL (i.e. the key is absent or the value is JSON null).

=head2 is_not_null

  jsonb('me.data', 'email')->is_not_null
  # WHERE (me.data->>?) IS NOT NULL

=head2 as_order

  $rs->search( {}, { order_by => jsonb('me.score', 'total')->as_order } )
  # ORDER BY (me.score->>?)    bind: total

Returns a literal-with-bind fragment suitable for use as an C<order_by> value. Combine with
C<-asc>/C<-desc> wrappers as usual:

  { order_by => { -desc => jsonb('me.score', 'total')->as_order } }
  # ORDER BY (me.score->>?) DESC

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::JSONB> — the C<jsonb()> helper that builds these objects

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
