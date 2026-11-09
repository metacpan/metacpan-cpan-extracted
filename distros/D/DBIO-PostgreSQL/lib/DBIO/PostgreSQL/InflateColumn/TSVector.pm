package DBIO::PostgreSQL::InflateColumn::TSVector;
# ABSTRACT: Auto-inflate/deflate PostgreSQL tsvector columns to/from Perl data structures

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

  return unless $class->_tsvector_type_info($info->{data_type});

  # this bailout is intentional
  return if exists $info->{inflate_tsvector} && !$info->{inflate_tsvector};

  $class->inflate_column(
    $column => {
      inflate => sub {
        my ($value, $obj) = @_;
        return $class->_inflate_tsvector_value($value);
      },
      deflate => sub {
        my ($value, $obj) = @_;
        return $class->_deflate_tsvector_value($value);
      },
    }
  );

  return;
}

# True for a tsvector data_type, false for anything else. Whitespace-tolerant,
# so ' tsvector ' is recognised (karr k61). tsvector takes no type modifier.
sub _tsvector_type_info {
  my ($class, $data_type) = @_;
  return unless defined $data_type;
  return unless $data_type =~ /\A\s*tsvector\s*\z/i;
  return 'tsvector';
}

sub _inflate_tsvector_value {
  my ($class, $value) = @_;

  return $value unless defined $value;
  return $value if ref $value;   # already a structure — pass through

  # empty tsvector prints as '' — represent it as an empty lexeme map
  return {} if $value =~ /\A\s*\z/;

  my %lexemes;
  while ($value =~ /\G\s*'((?:[^']|'')*)'(?::(\S+))?/gc) {
    my ($lexeme, $positions) = ($1, $2);
    $lexeme =~ s/''/'/g;
    $lexemes{$lexeme} = defined $positions ? [ split /,/, $positions ] : [];
  }

  # if the whole string wasn't consumed it isn't a tsvector literal — pass
  # it through untouched rather than returning a half-parsed structure
  return $value unless $value =~ /\G\s*\z/gc;

  return \%lexemes;
}

sub _deflate_tsvector_value {
  my ($class, $value) = @_;

  # plain strings pass through verbatim — never double-serialize
  return $value unless ref $value;

  return $class->_deflate_tsvector_hash($value)  if ref $value eq 'HASH';
  return $class->_deflate_tsvector_array($value) if ref $value eq 'ARRAY';

  Carp::croak('a tsvector column expects a hashref, an arrayref, or a tsvector string');
}

sub _deflate_tsvector_hash {
  my ($class, $value) = @_;

  my @parts;
  for my $lexeme (sort keys %$value) {
    my $positions = $value->{$lexeme};
    my @pos = ref $positions eq 'ARRAY' ? @$positions
            : defined $positions        ? ($positions)
            :                             ();
    my $quoted = $class->_quote_lexeme($lexeme);
    push @parts, @pos ? "$quoted:" . join(',', @pos) : $quoted;
  }

  return join(' ', @parts);
}

sub _deflate_tsvector_array {
  my ($class, $value) = @_;

  return join(' ', map { $class->_quote_lexeme($_) } @$value);
}

sub _quote_lexeme {
  my ($class, $lexeme) = @_;
  $lexeme =~ s/'/''/g;
  return "'$lexeme'";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::InflateColumn::TSVector - Auto-inflate/deflate PostgreSQL tsvector columns to/from Perl data structures

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::DB::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');   # loads this component

  __PACKAGE__->add_columns(
    body_search => { data_type => 'tsvector' },
  );

Then treat the column as a Perl data structure:

  # store: hashref of lexeme => [ positions ]
  $row->update({ body_search => { cat => [3], fat => [2, 4], rat => ['5A'] } });
  # stored as   'cat':3 'fat':2,4 'rat':5A

  # or a bare list of words (positionless lexemes)
  $row->update({ body_search => [qw( cat dog )] });  # stored as 'cat' 'dog'

  # read back: hashref of lexeme => [ positions ]
  my $tsv = $row->body_search;   # { cat => ['3'], fat => ['2','4'], rat => ['5A'] }

=head1 DESCRIPTION

This component translates C<tsvector> column data between PostgreSQL's text
input/output format and a Perl data structure, following the
L<DBIO::InflateColumn::DateTime> pattern: a C<register_column> hook that calls
L<DBIO::InflateColumn/inflate_column> for the columns it recognises.

It is loaded automatically by L<DBIO::PostgreSQL::Result>, so declaring a
C<tsvector> column is the whole opt-in (ADR 0006 — declaring the column is the
whole opt-in) — no user glue. The mapping:

=over 4

=item * B<inflate> (fetch): the tsvector output form
C<< 'cat':3 'fat':2,4 'rat':5A >> — sorted, distinct lexemes, each optionally
followed by C<:> and a comma-separated position list — becomes a HashRef
C<< { cat => ['3'], fat => ['2','4'], rat => ['5A'] } >>. A positionless lexeme
maps to an empty ArrayRef. Positions are kept verbatim as strings, so a weight
suffix (C<A>–C<D>, e.g. C<'5A'>) is never lost. The empty tsvector (PostgreSQL
prints it as C<''>) inflates to C<{}>.

=item * B<deflate> (insert/update bind): a HashRef
C<< { lexeme => [ positions ] } >> deflates to a raw tsvector literal, lexemes
sorted, C<< 'lexeme':p1,p2 >> when it has positions and bare C<'lexeme'> when it
does not. A value that is a plain scalar (or undef) rather than an ArrayRef is
treated as a single (or no) position. An ArrayRef of words deflates to
positionless lexemes C<< 'cat' 'dog' >>. Single quotes inside a lexeme are
doubled.

=back

Deflate produces a B<bind value> (a string), not SQL, so it emits a raw
tsvector literal rather than a C<to_tsvector(...)> call: a function call is SQL
and cannot be bound as a parameter. Feed C<to_tsvector()> through a literal
expression in C<search>/C<update> when you want the server to normalise text;
this component's job is the value on the wire.

The conversion is idempotent: a plain string is passed through verbatim on both
directions, so an already-serialized value is never double-serialized, and a
fetched value that does not look like a tsvector literal is returned as-is
rather than mangled. Non-tsvector columns are untouched.

=head1 METHODS

=head2 register_column

Chains with the L<DBIO::Row/register_column> method, and sets up C<tsvector>
columns appropriately. This would not normally be directly called by end users.

=head1 COLUMN INFO

=over 4

=item C<< inflate_tsvector => 0 >>

Opt out of inflation for a single column whose C<data_type> would otherwise
trigger it, mirroring C<inflate_datetime =E<gt> 0> in
L<DBIO::InflateColumn::DateTime>:

  __PACKAGE__->add_columns(
    body_search => { data_type => 'tsvector', inflate_tsvector => 0 },
  );

=back

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::Result> — the Result component that loads this one

=item * L<DBIO::PostgreSQL::InflateColumn::Vector> — the sibling component that
inflates pgvector columns, whose pattern this one follows

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
