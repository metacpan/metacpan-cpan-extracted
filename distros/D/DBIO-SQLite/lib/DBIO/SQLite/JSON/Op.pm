package DBIO::SQLite::JSON::Op;
# ABSTRACT: SQLite JSON path-extraction operator object built by json()

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();


sub new {
  my ($class, %args) = @_;
  return bless \%args, $class;
}

# The selectors build the extraction expression. The path is bound, never
# interpolated -- a JSON path is caller data and belongs in a placeholder, not
# in the SQL string. Each returns a fresh Op carrying ($sql, @bind) so the
# column-only object stays reusable, exactly like Vector::Op's distance methods.
sub _select {
  my ($self, $sql, @bind) = @_;
  return bless {
    col  => $self->{col},
    sql  => $sql,
    bind => \@bind,
  }, ref $self;
}

sub extract {
  my ($self, $path) = @_;
  return $self->_select( sprintf('json_extract(%s, ?)', $self->{col}), $path );
}


sub get {
  my ($self, $path) = @_;
  return $self->_select( sprintf('%s -> ?', $self->{col}), $path );
}


sub get_text {
  my ($self, $path) = @_;
  return $self->_select( sprintf('%s ->> ?', $self->{col}), $path );
}


sub _require_selector {
  my ($self) = @_;
  Carp::croak(
    'no JSON path selected — call a selector (extract/get/get_text) first'
  ) unless defined $self->{sql};
}

sub _op {
  my ($self, $op, $val) = @_;
  $self->_require_selector;
  return \[ sprintf('(%s) %s ?', $self->{sql}, $op), @{ $self->{bind} }, $val ];
}

sub eq { $_[0]->_op('=', $_[1]) }


sub ne { $_[0]->_op('!=', $_[1]) }


sub lt { $_[0]->_op('<', $_[1]) }


sub le { $_[0]->_op('<=', $_[1]) }


sub gt { $_[0]->_op('>', $_[1]) }


sub ge { $_[0]->_op('>=', $_[1]) }


sub like { $_[0]->_op('LIKE', $_[1]) }


sub is_null {
  my ($self) = @_;
  $self->_require_selector;
  return \[ sprintf('(%s) IS NULL', $self->{sql}), @{ $self->{bind} } ];
}


sub is_not_null {
  my ($self) = @_;
  $self->_require_selector;
  return \[ sprintf('(%s) IS NOT NULL', $self->{sql}), @{ $self->{bind} } ];
}


sub as_order {
  my ($self) = @_;
  $self->_require_selector;
  return \[ $self->{sql}, @{ $self->{bind} } ];
}


sub as_select {
  my ($self, $alias) = @_;
  $self->_require_selector;
  Carp::croak('as_select requires an alias') unless defined $alias and length $alias;
  return \[ sprintf('%s AS %s', $self->{sql}, $alias), @{ $self->{bind} } ];
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::JSON::Op - SQLite JSON path-extraction operator object built by json()

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Operator object representing a JSON path extraction against a SQLite column.
You do not construct this class directly — use the C<json()> helper from
L<DBIO::SQLite::JSON>:

  use DBIO::SQLite::JSON qw(json);

  my $expr = json('me.data')->get_text('$.status');  # DBIO::SQLite::JSON::Op
  $rs->search( $expr->eq('active') );                 # WHERE (me.data ->> ?) = ?

The object is built in two stages, mirroring L<DBIO::PostgreSQL::Vector::Op>:

=over 4

=item * C<json($col)> returns a column-only operator.

=item * A B<selector> method — L</extract>, L</get> or L</get_text> — chooses the
extraction form and the path, and returns a fresh operator carrying the rendered
SQL and its bind. The path always travels as a placeholder bind, never inlined.

=item * A B<consumption> method — a comparison (L</eq> …), L</is_null>,
L</as_order> or L</as_select> — turns that into an L<SQL::Abstract>
literal-with-bind fragment.

=back

L</extract> emits the C<json_extract> function (JSON1, SQLite 3.9+); L</get> and
L</get_text> emit the C<< -> >> and C<<< ->> >>> operators, which need SQLite 3.38+.

=head1 METHODS

=head2 extract

  json('me.data')->extract('$.status')
  # json_extract(me.data, ?)     bind: '$.status'

The portable C<json_extract()> function form. The path is bound. Available
wherever the JSON1 extension is (SQLite 3.9+, compiled in by default).

=head2 get

  json('me.data')->get('$.status')
  # me.data -> ?                 bind: '$.status'

The C<< -> >> operator (SQLite 3.38+), which yields a B<JSON> value. Use for
extracting a sub-document; for comparing a scalar value use L</get_text>.

=head2 get_text

  json('me.data')->get_text('$.status')
  # me.data ->> ?                bind: '$.status'

The C<<< ->> >>> operator (SQLite 3.38+), which yields a B<text / SQL> value.
This is the natural form for scalar comparisons.

=head2 eq

  json('me.data')->get_text('$.status')->eq('active')
  # WHERE (me.data ->> ?) = ?    bind: '$.status', 'active'

=head2 ne

  json('me.data')->get_text('$.status')->ne('deleted')
  # WHERE (me.data ->> ?) != ?

=head2 lt

  json('me.stats')->get_text('$.score')->lt(50)
  # WHERE (me.stats ->> ?) < ?

=head2 le

  json('me.stats')->get_text('$.score')->le(100)
  # WHERE (me.stats ->> ?) <= ?

=head2 gt

  json('me.stats')->get_text('$.score')->gt(100)
  # WHERE (me.stats ->> ?) > ?

=head2 ge

  json('me.stats')->get_text('$.score')->ge(100)
  # WHERE (me.stats ->> ?) >= ?

=head2 like

  json('me.data')->get_text('$.name')->like('John%')
  # WHERE (me.data ->> ?) LIKE ?

=head2 is_null

  json('me.data')->get_text('$.avatar')->is_null
  # WHERE (me.data ->> ?) IS NULL

=head2 is_not_null

  json('me.data')->get_text('$.email')->is_not_null
  # WHERE (me.data ->> ?) IS NOT NULL

=head2 as_order

  $rs->search( {}, { order_by => json('me.data')->get_text('$.total')->as_order } )
  # ORDER BY me.data ->> ?

Returns a literal-with-bind fragment for an C<order_by> value; the path travels
as a bind. Combine with C<-asc>/C<-desc> as usual:

  { order_by => { -desc => json('me.data')->get_text('$.total')->as_order } }
  # ORDER BY me.data ->> ? DESC

=head2 as_select

  $rs->search( {}, { select => [ json('me.data')->extract('$.status')->as_select('status') ] } )
  # SELECT json_extract(me.data, ?) AS status

Returns a literal-with-bind fragment selecting the extracted value under
C<$alias>. C<$alias> is emitted verbatim — pass an identifier, not user input.

=head1 SEE ALSO

=over 4

=item * L<DBIO::SQLite::JSON> — the C<json()> helper that builds these objects

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
