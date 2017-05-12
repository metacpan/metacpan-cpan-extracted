package App::perl2js::Converter::Node::Block;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node::BlockStmt';

use App::perl2js::Node::Block;

sub to_js_ast {
    my ($self, $context) = @_;
    return App::perl2js::Node::Block->new(
        token => $self->token,
        statements => [ map { $_->to_js_ast($context) } @{$self->statements} ],
    );
}

1;
