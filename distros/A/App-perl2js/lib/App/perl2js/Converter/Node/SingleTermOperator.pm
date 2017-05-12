package App::perl2js::Converter::Node::SingleTermOperator;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use App::perl2js::Converter::Node::Nop;

use App::perl2js::Node::PostSingleTermOperator;
use App::perl2js::Node::PreSingleTermOperator;

sub expr { shift->{expr} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    my $token = $self->token;
    if ($token->data eq '++' ||
        $token->data eq '--') {
        # TODO. Compiler::Parser cannot distinguish pre/post.
        #       temporary use PostSingleTermOperator...
        return App::perl2js::Node::PostSingleTermOperator->new(
            token => $token,
            expr  => $self->expr->to_js_ast($context),
        );
    } elsif ($token->name eq 'Add') {
        # Add do nothing.
        $token->{data} = '';
        return App::perl2js::Node::PreSingleTermOperator->new(
            token => $token,
            expr  => $self->expr->to_js_ast($context),
        );
    } else {
        return App::perl2js::Node::PreSingleTermOperator->new(
            token => $token,
            expr  => $self->expr->to_js_ast($context),
        );
    }
}

1;
