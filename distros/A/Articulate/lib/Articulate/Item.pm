package Articulate::Item;
use strict;
use warnings;
use Moo;

=head1 NAME

Articulate::Item - represent an item

=cut

=head1 SYNOPSIS

  Articulate::Item->new( {
    meta     => {},
    content  => 'Hello, World!',
    location => 'zone/public/article/hello-world',
  } );

  # Construction defaults to item if no better option is available
  Articulate::Construction->construct( { ... } );

An item is a simple storage class for any sort of item which. Items
have metadata, content, and a location.

Although it is acceptable to create items using the C<new> class
method, it is recommended that you construct items using
L<Articulate::Construction>, which will be able to pick an appropriate
subclass of item to construct based on the argument you supply, if you
have configured it to do so. Such a subclass can have semantically
appropriate methods available (see C<_meta_accessor> below for
information on how to create these).

=head1 ATTRIBUTES

=head3 location

Returns the location of the item, as a location object (see
L<Articulate::Location>). Coerces into a location using
C<Articulate::Location::new_location>.

=cut

has location => (
  is      => 'rw',
  default => sub { Articulate::Location->new; },
  coerce  => sub { Articulate::Location::new_location(shift); }
);

=head3 meta

Returns the item's metadata, as a hashref.

=cut

has meta => (
  is      => 'rw',
  default => sub { {} },
);

=head3 content

Returns the item's content. What it might look like depends entirely on
the content. Typically this is an unblessed scalar value, but it MAY
contain binary data or an L<Articulate::File> object.

=cut

has content => (
  is      => 'rw',
  default => sub { '' },
);

=head1 METHOD

=head3 _meta_accessor

  # In a subclass of Item
  sub author { shift->_meta_accessor('schema/article/author')->(@_) }

  # Then, on that subclass
  $article->author('user/alice');
  $article->author;

Uses dpath_set or dpath_get from L<Articulate::Syntax> to find or
assign the relevant field in the metadata.

=cut

sub _meta_accessor {
  my $self = shift;
  my $path = shift;
  return sub {
    if (@_) {
      dpath_set( $self->meta, $path, @_ );
    }
    else {
      dpath_get( $self->meta, $path );
    }
    }
}

1;
