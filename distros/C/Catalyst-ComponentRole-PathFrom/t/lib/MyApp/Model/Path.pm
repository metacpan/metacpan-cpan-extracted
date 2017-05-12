package MyApp::Model::Path;

use Moose;

extends 'Catalyst::Component';
with 'Catalyst::ComponentRole::PathFrom',
  'Catalyst::Component::InstancePerContext';

has ctx => (is=>'rw', weak_ref=>1);

sub build_per_context_instance {
  my ($self, $c) = @_;
  $self->ctx($c);
  return $self;
}

around 'path_from', sub {
  my ($orig, $self, @args) = @_;
  return $self->$orig($self->ctx, @args);
};

__PACKAGE__->meta->make_immutable;
