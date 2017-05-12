package Articulate::Flow::MetaSwitch;
use strict;
use warnings;
use Moo;
with 'Articulate::Role::Flow';
use Articulate::Syntax qw (instantiate instantiate_array dpath_get);

=head1 NAME

Articulate::Flow::MetaSwitch - case switching on metadata

=head1 CONFIGURATION

  - class: Articulate::Flow::MetaSwitch
    args:
      field: schema/core/content_type
      where:
        'text/markdown':
          - Articulate::Enrichment::Markdown
      otherwise:
        - SomeOther::Enrichment
  - class: Articulate::Flow::MetaSwitch
    args:
      where:
        - field: schema/core/file
          then:
            - Handle::File
      otherwise:
        - Assuming::Text

=head1 DESCRIPTION

This provides a convenient interface to a common branching pattern. When performing actions like C<enrich> and C<augment>, a developer will typically want to make some processes dependant on the metadata of that content.

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

=cut

has field => ( is => 'rw', );

has where => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub {
    my $orig = shift // [];
    if ( ref $orig eq ref {} ) {
      foreach my $type ( keys %$orig ) {
        $orig->{$type} = instantiate_array( $orig->{$type} );
      }
    }
    else {
      foreach my $rule (@$orig) {
        $rule->{then} = instantiate_array( $rule->{then} );
      }
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
  my $self   = shift;
  my $method = shift;
  my $item   = shift;
  if ( ref $self->where eq ref {} ) {
    my $field = $self->field;
    my $actual_value = dpath_get( $item->meta, $field );
    foreach my $value ( keys %{ $self->where } ) {
      if ( $value eq $actual_value ) {
        return $self->_delegate( $method => $self->where->{$value},
          [ $item, @_ ] );
      }
    }
  }
  if ( ref $self->where eq ref [] ) {
    foreach my $where ( @{ $self->where } ) {
      my $actual_value = dpath_get( $item->meta, $where->{field} );
      if (
        ( !defined $where->{value} and defined $actual_value )
        || ( defined $where->{value}
          and $where->{value} eq $actual_value ) # this is naive!
        )
      {
        return $self->_delegate( $method => $where->{then}, [ $item, @_ ] );
      }
    }
  }
  if ( defined $self->otherwise ) {
    return $self->_delegate( $method => $self->otherwise, [ $item, @_ ] );
  }
  return $item;
}

1;
