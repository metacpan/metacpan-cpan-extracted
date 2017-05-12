package App::perl2js::Node::Branch;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

use App::perl2js::Node::Nop;

sub left {
    my ($self) = @_;
    return $self->{left} // App::perl2js::Node::Nop->new;
}

sub right {
    my ($self) = @_;
    return $self->{right} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        $self->left->to_javascript($depth),
        $self->token->data,
        $self->right->to_javascript($depth),
    );
}

1;
