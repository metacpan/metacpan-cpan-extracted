package Example::View::HTML;

use Moose;
extends 'Catalyst::View::MojoTemplate';

__PACKAGE__->config(helpers=>+{
  now => sub {
    my ($self, $c, @args) = @_;
    return localtime;
  },
});

__PACKAGE__->meta->make_immutable;
