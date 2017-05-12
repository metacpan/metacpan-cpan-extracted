package Test2::Role::DefaultAction;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

sub default :Default {
    my ($self_controller,$c) = @_;

    $c->res->body('default action');
    $c->res->code(404);
}

1;
