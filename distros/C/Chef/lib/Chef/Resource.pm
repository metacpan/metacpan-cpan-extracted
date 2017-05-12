package Chef::Resource;

use warnings;
use strict;

use Moose;

has 'name'          => ( is => 'rw', isa => 'Str', required => 1 );
has 'resource_type' => ( is => 'rw', isa => 'Str', required => 1 );
has 'resource_sub'  => ( is => 'rw', isa => 'CodeRef' );
has 'options' => ( is => 'rw', isa => 'HashRef', default => sub { {}; } );

sub evaluate {
  my $self = shift;
  my $sub  = shift;

  my $meta = __PACKAGE__->meta;
  $meta->add_method( 'run_me' => $self->resource_sub );
  $self->run_me($self);
}

sub ruby_class {
  my $self  = shift;
  my $class = 'Chef::Resource';
  my @parts = split( '_', $self->resource_type );
  foreach my $bit (@parts) {
    $class = $class . '::' . ucfirst($bit);
  }
  return $class;
}

sub prepare_json {
  my $self = shift;
  my $cr   = {};
  $cr->{'instance_vars'} = { '@name' => $self->name, };
  foreach my $key ( keys( %{ $self->options } ) ) {
    $cr->{'instance_vars'}->{ "@" . $key } = $self->options->{$key};
  }
  $cr->{'json_class'} = $self->ruby_class;
  return $cr;
}

sub AUTOLOAD {
  my $self = shift;
  my $attr = $Chef::Resource::AUTOLOAD;
  $attr =~ s/.*:://;
  return unless $attr =~ /[^A-Z]/;
  $self->options->{$attr} = shift(@_) if @_;
  return $self->options->{$attr};
}

=head1 COPYRIGHT & LICENSE

Copyright 2009 Opscode, Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
