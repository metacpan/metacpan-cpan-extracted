package App::perl2js::Converter::Node::Hash;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use Compiler::Lexer::Token;
use App::perl2js::Converter::Node::Nop;
use App::perl2js::Converter::Node::Leaf;

use App::perl2js::Node::PropertyAccessor;

sub key { shift->{key} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    my $key;
    if (ref($self->key) eq 'App::perl2js::Converter::Node::HashRef') {
        $key = $self->key->data_node;
    } else {
        $key = $self->key;
    }
    return App::perl2js::Node::PropertyAccessor->new(
        token => $self->token,
        data  => App::perl2js::Converter::Node::Leaf->new(
            token => bless({
                data => $self->data,
                name => 'Var',
            }, 'Compiler::Lexer::Token')
        )->to_js_ast($context),
        key   => $key->to_js_ast($context),
    );
}

1;
