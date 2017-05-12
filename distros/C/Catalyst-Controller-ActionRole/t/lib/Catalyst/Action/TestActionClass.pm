package Catalyst::Action::TestActionClass;

use Moose;
use namespace::clean -except => 'meta';

extends 'Catalyst::Action';

sub execute {
    my ( $self, $controller, $c ) = @_;
    $c->response->body(__PACKAGE__);
};

__PACKAGE__->meta->make_immutable;

1;
