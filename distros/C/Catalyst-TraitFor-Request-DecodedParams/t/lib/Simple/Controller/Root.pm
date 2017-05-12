package Simple::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => q{});

sub default : Private {
    my ( $self, $c ) = @_;
    $c->res->body('Simple app test');
}

1;
