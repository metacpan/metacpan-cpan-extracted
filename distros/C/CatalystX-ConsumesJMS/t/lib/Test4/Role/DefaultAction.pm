package Test4::Role::DefaultAction;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

sub default :Default {
    my ($self_controller,$c) = @_;

    $c->stash->{message} ||= {default=>'response'};
    $c->res->header('X-Reply-Address'=>'reply-address');
}

1;
