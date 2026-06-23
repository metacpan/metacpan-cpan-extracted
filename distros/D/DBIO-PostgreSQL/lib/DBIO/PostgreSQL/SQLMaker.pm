package DBIO::PostgreSQL::SQLMaker;
# ABSTRACT: PostgreSQL-specific SQL generation for DBIO

use strict;
use warnings;

use base 'DBIO::SQLMaker';

use JSON::MaybeXS ();

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my %JSONB_OP = (
  '@>' => '_where_op_jsonb_contains',
  '<@' => '_where_op_jsonb_contains',
  '@?' => '_where_op_jsonb_path',
  '@@' => '_where_op_jsonb_path',
  '?'  => '_where_op_jsonb_exists',
  '?|' => '_where_op_jsonb_exists',
  '?&' => '_where_op_jsonb_exists',
);

sub new {
  my $class = shift;
  my %opts  = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

  # Register the JSONB operators with the new-style expand_op mechanism (the
  # base DBIO::SQLMaker disables the old special_ops system). Each handler
  # keeps its original ($self, $col, $op, $val) -> ($sql, @bind) signature; we
  # wrap its output in a -literal node.
  for my $op (keys %JSONB_OP) {
    my $meth = $JSONB_OP{$op};
    $opts{expand_op}{$op} ||= sub {
      my ($self, $op, $v, $k) = @_;
      return +{ -literal => [ $self->$meth($k, $op, $v) ] };
    };
  }

  $class->next::method( \%opts );
}


sub _where_op_jsonb_contains {
  my ( $self, $col, $op, $val ) = @_;

  my $quoted = $self->_quote($col);

  if ( ref $val eq 'SCALAR' ) {
    return ( sprintf( '%s %s %s', $quoted, $op, $$val ), () );
  }

  my $json =
      ( ref $val eq 'HASH' || ref $val eq 'ARRAY' )
    ? $JSON->encode($val)
    : $val;    # already a JSON string

  return ( sprintf( '%s %s ?::jsonb', $quoted, $op ), $json );
}


sub _where_op_jsonb_path {
  my ( $self, $col, $op, $val ) = @_;

  my $quoted = $self->_quote($col);
  return ( sprintf( '%s %s ?::jsonpath', $quoted, $op ), $val );
}


sub _where_op_jsonb_exists {
  my ( $self, $col, $op, $val ) = @_;

  my $quoted = $self->_quote($col);

  if ( $op eq '?' ) {
    return ( sprintf( 'jsonb_exists(%s, ?)', $quoted ), $val );
  }

  my @keys = ref $val eq 'ARRAY' ? @$val : ($val);
  my $arr  = 'ARRAY[' . join( ', ', ('?') x scalar @keys ) . ']';

  if ( $op eq '?|' ) {
    return ( sprintf( 'jsonb_exists_any(%s, %s)', $quoted, $arr ), @keys );
  }
  else {    # ?&
    return ( sprintf( 'jsonb_exists_all(%s, %s)', $quoted, $arr ), @keys );
  }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::SQLMaker - PostgreSQL-specific SQL generation for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for PostgreSQL. Extends standard SQL generation
with native support for PostgreSQL JSONB operators.

Used automatically by L<DBIO::PostgreSQL::Storage> — the C<sql_maker_class>
is set on the storage and this class is instantiated transparently whenever a
PostgreSQL connection is opened.

=head2 Containment: C<@>> and C<<@>

Tests whether a JSONB value contains (or is contained by) another JSONB
value. The RHS hashref or arrayref is JSON-encoded automatically.

  $rs->search({ 'me.data' => { '@>' => { status => 'active' } } });
  # WHERE "me"."data" @> '{"status":"active"}'::jsonb

  $rs->search({ 'me.tags' => { '<@' => ['a', 'b'] } });
  # WHERE "me"."tags" <@ '["a","b"]'::jsonb

=head2 Key existence: C<?>, C<?|>, C<?&>

Tests whether a JSONB object has a specific key (or any/all keys from a list).
These operators are rewritten as C<jsonb_exists*()> functions to avoid
conflicts with DBI's C<?> placeholder syntax.

  $rs->search({ 'me.data' => { '?'  => 'email' } });
  # WHERE jsonb_exists("me"."data", ?)

  $rs->search({ 'me.data' => { '?|' => [qw(email phone)] } });
  # WHERE jsonb_exists_any("me"."data", ARRAY[?, ?])

  $rs->search({ 'me.data' => { '?&' => [qw(name email)] } });
  # WHERE jsonb_exists_all("me"."data", ARRAY[?, ?])

=head2 JSONPath: C<@?> and C<@@> (PostgreSQL 12+)

Evaluates a JSONPath expression against a JSONB value.

  $rs->search({ 'me.data' => { '@?' => '$.status == "active"' } });
  # WHERE "me"."data" @? '$.status == "active"'::jsonpath

  $rs->search({ 'me.data' => { '@@' => '$.score > 10' } });
  # WHERE "me"."data" @@ '$.score > 10'::jsonpath

=head2 Path extraction

For comparing individual fields within a JSONB value, see
L<DBIO::PostgreSQL::JSONB> which provides the C<jsonb()> path expression
helper:

  use DBIO::PostgreSQL::JSONB qw(jsonb);
  $rs->search( jsonb('me.data', 'status')->eq('active') );
  # WHERE (me.data->>'status') = ?

=head1 METHODS

=head2 new

Extends the base constructor to register JSONB C<special_ops>. Called
automatically by L<DBIO::PostgreSQL::Storage> — no need to instantiate this
class directly.

=head2 _where_op_jsonb_contains

Handles the C<@>> (contains) and C<<@> (contained by) operators.

The RHS may be:

=over 4

=item * B<hashref or arrayref> — JSON-encoded automatically and bound with a
C<::jsonb> cast:

  { 'me.data' => { '@>' => { status => 'active' } } }
  # WHERE "me"."data" @> '{"status":"active"}'::jsonb

  { 'me.tags' => { '@>' => ['admin', 'user'] } }
  # WHERE "me"."tags" @> '["admin","user"]'::jsonb

  { 'me.data' => { '<@' => { role => 'guest' } } }
  # WHERE "me"."data" <@ '{"role":"guest"}'::jsonb

=item * B<plain string> — treated as a pre-encoded JSON string, bound as-is:

  { 'me.data' => { '@>' => '{"status":"active"}' } }
  # WHERE "me"."data" @> '{"status":"active"}'::jsonb

=item * B<scalar ref> — embedded as literal SQL without binding (use for
sub-selects or other column references):

  { 'me.data' => { '@>' => \'other_col' } }
  # WHERE "me"."data" @> other_col

=back

=head2 _where_op_jsonb_path

Handles C<@?> (jsonpath predicate) and C<@@> (jsonpath match) operators
(PostgreSQL 12+). The RHS is bound as a C<::jsonpath> cast.

  { 'me.data' => { '@?' => '$.status == "active"' } }
  # WHERE "me"."data" @? '$.status == "active"'::jsonpath

  { 'me.data' => { '@@' => '$.score > 10' } }
  # WHERE "me"."data" @@ '$.score > 10'::jsonpath

=head2 _where_op_jsonb_exists

Handles the C<?> (key exists), C<?|> (any key exists), and C<?&> (all keys
exist) operators. Because C<?> would conflict with DBI's placeholder syntax,
these operators are rewritten as PostgreSQL functions.

  { 'me.data' => { '?'  => 'email' } }
  # WHERE jsonb_exists("me"."data", ?)

  { 'me.data' => { '?|' => [qw(email phone)] } }
  # WHERE jsonb_exists_any("me"."data", ARRAY[?, ?])

  { 'me.data' => { '?&' => [qw(name email)] } }
  # WHERE jsonb_exists_all("me"."data", ARRAY[?, ?])

A single string is accepted for C<?|> and C<?&> as a convenience (treated as
a one-element list):

  { 'me.data' => { '?|' => 'email' } }
  # WHERE jsonb_exists_any("me"."data", ARRAY[?])

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::Storage> — PostgreSQL storage (uses this SQL maker)

=item * L<DBIO::PostgreSQL::JSONB> — path expression DSL for JSONB columns

=item * L<DBIO::SQLMaker> — base SQL maker class

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
