package Example::View::Factory;

use Moose;

extends 'Catalyst::View::BasePerRequest';

has name => (is=>'ro', required=>1);

sub prepare_build_args {
  my ($class, $c, %args) = @_;
  $args{name} = "prepared_$args{name}";
  return %args;
}

sub render {
  my ($self, $c) = @_;
  return "<div>Hello @{[ $self->name ]}!</div>";
}

__PACKAGE__->config(
  content_type => 'text/html', 
  status_codes => [200,201,400],
  lifecycle => 'Factory',
);

__PACKAGE__->meta->make_immutable();
