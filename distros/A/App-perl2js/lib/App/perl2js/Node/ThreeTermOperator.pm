package App::perl2js::Node::ThreeTermOperator;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

use App::perl2js::Node::Nop;

sub cond {
    my ($self) = @_;
    return $self->{cond} // App::perl2js::Node::Nop->new;
}

sub true_expr {
    my ($self) = @_;
    return $self->{true_expr} // App::perl2js::Node::Nop->new;
}

sub false_expr {
    my ($self) = @_;
    return $self->{false_expr} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        $self->cond->to_javascript($depth),
        " ? ",
        $self->true_expr->to_javascript($depth),
        " : ",
        $self->false_expr->to_javascript($depth),
    );
}

1;
