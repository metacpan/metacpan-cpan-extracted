package App::perl2js::Node::WhileStmt;

use strict;
use warnings;
use parent qw(App::perl2js::Node::BlockStmt);

use App::perl2js::Node::Nop;

sub expr {
    my ($self) = @_;
    return $self->{expr} // App::perl2js::Node::Nop->new;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        "while (",
        $self->expr->to_javascript,
        ") {\n",
        $self->sentences_to_javascript($depth + 1),
        $self->indent($depth),
        "}",
    );
}

1;
