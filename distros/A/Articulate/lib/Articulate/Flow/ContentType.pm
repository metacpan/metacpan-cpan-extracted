package Articulate::Flow::ContentType;
use strict;
use warnings;
use Moo;
with 'Articulate::Role::Flow';
use Articulate::Syntax qw (instantiate instantiate_array);

=head1 NAME

Articulate::Flow::ContentType - case switching for content_type

=head1 CONFIGURATION

  - class: Articulate::Flow::ContentType
    args:
      where:
        'text/markdown':
          - Articulate::Enrichment::Markdown
      otherwise:
        - SomeOther::Enrichment

=head1 DESCRIPTION

This provides a convenient interface to a common branching pattern. When performing actions like C<enrich> and C<augment>, a developer will typically want to make some processes dependant on what type of content is stored in the item.

Rather than having to write a 'black box' provider every time, this class provides a standard way of doing it.

=head1 METHODS

=head3 enrich

    $self->enrich( $item, $request );
    $self->process_method( enrich => $item, $request );

=head3 augment

    $self->augment( $item, $request );
    $self->process_method( augment => $item, $request );

=head3 process_method

  $self->process_method( $verb, $item, $request );

Goes through each of the keys of C<< $self->where >>; if the key is equal to the C<content_type> of C<$item>, then instantiates the value of that key and performs the same verb on the arguments.

If none of the where clauses matched, the otherwise provider, if one is specified, will be used.

An item's C<content_type> is retrieved from C<meta.schema.core.content_type>.

=cut

has where => (
  is      => 'rw',
  default => sub { {} },
  coerce  => sub {
    my $orig = shift // {};
    foreach my $type ( keys %$orig ) {
      $orig->{$type} = instantiate_array( $orig->{$type} );
    }
    return $orig;
  },
);

has otherwise => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub {
    instantiate_array(@_);
  },
);

sub process_method {
  my $self         = shift;
  my $method       = shift;
  my $item         = shift;
  my $content_type = $item->meta->{schema}->{core}->{content_type};
  if ( defined $content_type ) {
    foreach my $type ( keys %{ $self->where } ) {
      if ( $type eq $content_type ) {
        return $self->_delegate( $method => $self->where->{$type},
          [ $item, @_ ] );
      }
    }
  }
  if ( defined $self->otherwise ) {
    return $self->_delegate( $method => $self->otherwise, [ $item, @_ ] );
  }
  return $item;
}

1;
