package App::perl2js::Node::PostSingleTermOperator;

use strict;
use warnings;
use parent qw(App::perl2js::Node);

use App::perl2js::Node::Nop;

sub expr {
    my ($self) = @_;
    return $self->{expr} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        '(',
        $self->expr->to_javascript($depth),
        ')',
        $self->token->data,
    );
}

1;
