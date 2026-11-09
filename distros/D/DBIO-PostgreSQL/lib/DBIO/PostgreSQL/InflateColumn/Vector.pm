package DBIO::PostgreSQL::InflateColumn::Vector;
# ABSTRACT: Auto-inflate/deflate pgvector columns to/from Perl data structures

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';
use Carp ();
use namespace::clean;

__PACKAGE__->load_components('InflateColumn');



sub register_column {
  my ($class, $column, $info, @rest) = @_;

  $class->next::method($column, $info, @rest);

  my ($type, $dims) = $class->_pgvector_type_info($info->{data_type});
  return unless $type;

  # this bailout is intentional
  return if exists $info->{inflate_pgvector} && !$info->{inflate_pgvector};

  $dims //= $info->{size} if defined $info->{size} && $info->{size} =~ /\A\d+\z/;

  my $infcopy = { %$info };
  $class->inflate_column(
    $column => {
      inflate => sub {
        my ($value, $obj) = @_;
        return $class->_inflate_pgvector_value($type, $value);
      },
      deflate => sub {
        my ($value, $obj) = @_;
        return $class->_deflate_pgvector_value($type, $value, $dims);
      },
    }
  );

  return;
}

# Parses a pgvector data_type into (type, dims). Returns () for anything that
# is not a pgvector type. 'vector(3)' -> ('vector', 3); 'halfvec' -> ('halfvec', undef).
sub _pgvector_type_info {
  my ($class, $data_type) = @_;
  return unless defined $data_type;

  my ($type, $dims) = $data_type =~ /\A\s*(vector|halfvec|sparsevec)(?:\(\s*(\d+)\s*\))?\s*\z/i;
  return unless $type;

  return (lc $type, defined $dims ? 0 + $dims : undef);
}

sub _inflate_pgvector_value {
  my ($class, $type, $value) = @_;

  return $value unless defined $value;
  return $value if ref $value;   # already a structure — pass through

  return $class->_inflate_sparsevec($value) if $type eq 'sparsevec';
  return $class->_inflate_dense($value);
}

sub _deflate_pgvector_value {
  my ($class, $type, $value, $dims) = @_;

  # plain strings pass through verbatim — never double-serialize
  return $value unless ref $value;

  return $class->_deflate_sparsevec($value, $dims) if $type eq 'sparsevec';
  return $class->_deflate_dense($value);
}

sub _inflate_dense {
  my ($class, $value) = @_;

  return $value unless $value =~ /\A\s*\[.*\]\s*\z/s;

  my $inner = $value;
  $inner =~ s/\A\s*\[//;
  $inner =~ s/\]\s*\z//;

  return [] if $inner =~ /\A\s*\z/;

  return [ map { $class->_coerce_number($_) } map { _trim($_) } split /,/, $inner ];
}

sub _deflate_dense {
  my ($class, $value) = @_;

  Carp::croak('a vector/halfvec column expects an arrayref of numbers or a pgvector string')
    unless ref $value eq 'ARRAY';

  return '[' . join(',', @$value) . ']';
}

sub _inflate_sparsevec {
  my ($class, $value) = @_;

  return $value unless $value =~ /\A\s*\{.*\}\s*\/\s*\d+\s*\z/s;

  my ($body, $dims) = $value =~ /\A\s*\{(.*)\}\s*\/\s*(\d+)\s*\z/s;

  my %values;
  for my $pair (split /,/, $body) {
    next unless $pair =~ /\A\s*(\d+)\s*:\s*(.*?)\s*\z/;
    $values{$1} = $class->_coerce_number($2);
  }

  return { dims => 0 + $dims, values => \%values };
}

sub _deflate_sparsevec {
  my ($class, $value, $dims) = @_;

  Carp::croak('a sparsevec column expects a hashref or a pgvector string')
    unless ref $value eq 'HASH';

  my ($d, $values);
  if (exists $value->{dims} && ref $value->{values} eq 'HASH') {
    $d = $value->{dims};
    $values = $value->{values};
  }
  else {
    $values = $value;
    $d = $dims;
  }

  Carp::croak(
    'cannot deflate a sparsevec hashref without dimensions: '
      . 'declare the column as sparsevec(N) or pass { dims => N, values => { idx => val } }'
  ) unless defined $d;

  my $body = join(',', map { "$_:$values->{$_}" } sort { $a <=> $b } keys %$values);
  return "{$body}/$d";
}

# Numeric-looking values come back as numbers (the natural Perl shape for a
# vector); 'NaN'/'Infinity' and anything else stay strings.
sub _coerce_number {
  my ($class, $value) = @_;

  return $value unless $value =~ /\A-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\z/;
  return 0 + $value;
}

sub _trim {
  my ($value) = @_;
  $value =~ s/\A\s+//;
  $value =~ s/\s+\z//;
  return $value;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::InflateColumn::Vector - Auto-inflate/deflate pgvector columns to/from Perl data structures

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::DB::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');   # loads this component

  __PACKAGE__->add_columns(
    embedding => { data_type => 'vector(3)' },
    sparse    => { data_type => 'sparsevec(3)' },
  );

Then treat the columns as Perl data structures:

  $row->update({ embedding => [0.1, 0.2, 0.3] });   # stored as '[0.1,0.2,0.3]'
  my $v = $row->embedding;                          # [0.1, 0.2, 0.3]

  $row->update({ sparse => { 0 => 0.1, 2 => 0.2 } });  # stored as '{0:0.1,2:0.2}/3'
  my $s = $row->sparse;   # { dims => 3, values => { 0 => 0.1, 2 => 0.2 } }

=head1 DESCRIPTION

This component translates pgvector column data between PostgreSQL's text
input/output format and Perl data structures, following the
L<DBIO::InflateColumn::DateTime> pattern: a C<register_column> hook that calls
L<DBIO::InflateColumn/inflate_column> for the columns it recognises.

It is loaded automatically by L<DBIO::PostgreSQL::Result>, so declaring a
pgvector column is the whole opt-in — no user glue. The mapping:

=over 4

=item * C<vector(N)> / C<halfvec(N)> — dense vectors. An ArrayRef of numbers
deflates to C<[0.1,0.2]> on insert/update/search binds; C<[0.1,0.2]> inflates
back to an ArrayRef on fetch.

=item * C<sparsevec(N)> — sparse vectors. A HashRef deflates to
C<{i:v,...}/N>; C<{i:v,...}/N> inflates back to
C<< { dims => N, values => { i => v } } >> (the same shape the
L<DBIO::PostgreSQL::Vector> query DSL accepts). The dimensions come from the
column declaration C<sparsevec(N)>; a HashRef without an explicit
C<< { dims => N, values => {...} } >> wrapper on a dimension-less column is an
error rather than a guess.

=item * C<bit(N)> — B<not> inflated. pgvector binary vectors are plain
PostgreSQL C<bit(N)> columns, a general engine type rather than a pgvector
one, and their bitstring form is already the natural Perl representation
(C<'101010'> feeds the Hamming/Jaccard operators directly).

=back

The conversion is idempotent: a plain string is passed through verbatim on
both directions, so an already-serialized value (e.g. C<'[0.1, 0.2]'>) is
never double-serialized, and a fetched value that does not look like a
pgvector literal is returned as-is rather than mangled. Non-pgvector columns
are untouched.

=head1 METHODS

=head2 register_column

Chains with the L<DBIO::Row/register_column> method, and sets up pgvector
columns appropriately. This would not normally be directly called by end
users.

=head1 COLUMN INFO

=over 4

=item C<< inflate_pgvector => 0 >>

Opt out of inflation for a single column whose C<data_type> would otherwise
trigger it, mirroring C<inflate_datetime =E<gt> 0> in
L<DBIO::InflateColumn::DateTime>:

  __PACKAGE__->add_columns(
    embedding => { data_type => 'vector(3)', inflate_pgvector => 0 },
  );

=back

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::Result> — the Result component that loads this one

=item * L<DBIO::PostgreSQL::Vector> — the distance-query DSL, whose sparsevec
shape this component's inflate mirrors

=item * L<DBIO::InflateColumn::DateTime> — the component pattern this follows

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
