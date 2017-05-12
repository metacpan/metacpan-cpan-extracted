package App::perl2js::Converter::Node::WhileStmt;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node::BlockStmt';

use Compiler::Lexer::Token;

use App::perl2js::Converter::Node::Nop;
use App::perl2js::Converter::Node::SingleTermOperator;

use App::perl2js::Node::WhileStmt;

sub expr { shift->{expr} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    my $token = $self->token;
    my $expr;
    if ($token->name eq 'UntilStmt') {
        $expr = App::perl2js::Converter::Node::SingleTermOperator->new(
            token => bless({
                data => '!',
                name => '', # TODO
            }, 'Compiler::Lexer::Token'),
            expr => $self->expr,
        );
    } else {
        $expr = $self->expr;
    }
    return App::perl2js::Node::WhileStmt->new(
        token => $self->token,
        expr  => $expr->to_js_ast($context),
        statements => [ map { $_->to_js_ast($context) } @{$self->statements} ],
    );
}

1;
