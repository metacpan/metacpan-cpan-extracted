package App::perl2js::Converter::Node::ThreeTermOperator;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use App::perl2js::Converter::Node::Nop;

use App::perl2js::Node::ThreeTermOperator;

sub cond { shift->{cond} // App::perl2js::Converter::Node::Nop->new; }
sub true_expr { shift->{true_expr} // App::perl2js::Converter::Node::Nop->new; }
sub false_expr { shift->{false_expr} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    return App::perl2js::Node::ThreeTermOperator->new(
        token => $self->token,
        cond  => $self->cond->to_js_ast($context),
        true_expr  => $self->true_expr->to_js_ast($context),
        false_expr => $self->false_expr->to_js_ast($context),
    );
}

1;
