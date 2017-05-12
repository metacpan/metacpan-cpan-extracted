package App::perl2js::Converter::Node::Module;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use App::perl2js::Converter::Node::Nop;
use App::perl2js::Node::Import;
use App::perl2js::Node::Nop;

sub args { shift->{args} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    my $token = $self->token;
    my $module_name = $token->data;

    # translate various modules to JavaScript
    if (
        $module_name eq 'strict' ||
        $module_name eq 'utf8' ||
        $module_name eq 'warnings'
    ) {
        return App::perl2js::Node::Nop->new;
    } elsif (
        $module_name eq 'base' ||
        $module_name eq 'parent'
    ) {
        my $base_name = ref($self->args) eq 'App::perl2js::Converter::Node::Leaf'
            ? $self->args->token->data
            : $self->args->expr->token->data;
        $self->token->{data} = $base_name;
        my $import = App::perl2js::Node::Import->new(
            token => $self->token,
        );
        $context->root->push_import($import);
        # $context->current_class->{super_class} = $base_name;
    } else {
        my $import = App::perl2js::Node::Import->new(
            token => $self->token,
        );
        $context->root->push_import($import);
    }
    return App::perl2js::Node::Nop->new;
}

1;
