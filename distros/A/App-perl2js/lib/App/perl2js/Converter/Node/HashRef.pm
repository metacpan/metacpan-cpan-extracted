package App::perl2js::Converter::Node::HashRef;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use App::perl2js::Converter::Node::Nop;

use App::perl2js::Node::ObjectLiteral;

sub data_node { shift->{data} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    return App::perl2js::Node::ObjectLiteral->new(
        token => $self->token,
        data  => $self->data_node->to_js_ast($context),
    );
}

1;
