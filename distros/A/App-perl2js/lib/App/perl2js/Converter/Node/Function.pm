package App::perl2js::Converter::Node::Function;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node::BlockStmt';

use App::perl2js::Converter::Node::Nop;

use App::perl2js::Node::Function;
use App::perl2js::Node::FunctionExpression;
use App::perl2js::Node::Method;

sub prototype {
    my ($self) = @_;
    return $self->{prototype};
}

sub to_js_ast {
    my ($self, $context) = @_;
    my $current_block = $context->current_block;

    my $statements = $self->statements;
    my $token = $self->token;

    my $is_code_ref = $token->name ne 'Function';
    my $block;
    if ($is_code_ref) {
        $block = App::perl2js::Node::FunctionExpression->new(
            token => $token,
            statements => [
                map { $_->to_js_ast($context->clone($block)) } @$statements
            ],
        )
    } elsif ($current_block->isa('App::perl2js::Node::Class')) {
        $block = App::perl2js::Node::Method->new(
            token => $token,
            statements => [
                map { $_->to_js_ast($context->clone($block)) } @$statements
            ],
        )
    } else {
        $block = App::perl2js::Node::Function->new(
            token => $token,
            statements => [
                map { $_->to_js_ast($context->clone($block)) } @$statements
            ],
        )
    }

    return $block;
}

1;
