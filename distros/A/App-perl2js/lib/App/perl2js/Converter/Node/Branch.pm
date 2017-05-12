package App::perl2js::Converter::Node::Branch;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use App::perl2js::Converter::Node::FunctionCall;
use App::perl2js::Converter::Node::Nop;

use App::perl2js::Node::Branch;
use App::perl2js::Node::PropertyAccessor;

sub left  { shift->{left}  // App::perl2js::Converter::Node::Nop->new; }
sub right { shift->{right} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    my $token = $self->token;
    my $name = $token->name;
    my $data = $token->data;
    my $left  = $self->left;
    my $right = $self->right;

    if ($name eq 'Add') {
        $token->{data} = " + ";
    } elsif ($name eq 'Mul') {
        $token->{data} = " * ";
    } elsif ($name eq 'Comma') {
        $token->{data} = ", ";
    } elsif ($name eq 'AlphabetOr') {
        $token->{data} = " || ";
    } elsif ($name eq 'AlphabetAnd') {
        $token->{data} = " && ";
    } elsif ($name eq 'And') {
        $token->{data} = " && ";
    } elsif ($name eq 'Arrow') {
        $token->{data} = ' : ';
    } elsif ($name eq 'Assign') {
        if ($left->token->name eq 'LocalHashVar' &&
            ref($right) eq 'App::perl2js::Converter::Node::List'
            ) {
            my $arrayref = bless +{
                data => $right,
                indent => $right->indent
            }, 'App::perl2js::Converter::Node::HashRef';
            $right->{parent} = $arrayref;
            $right = $arrayref;
        }
        if ($left->token->name eq 'LocalArrayVar' &&
            ref($right) eq 'App::perl2js::Converter::Node::List'
            ) {
            my $arrayref = bless +{
                data => $right,
                indent => $right->indent
            }, 'App::perl2js::Converter::Node::ArrayRef';
            $right->{parent} = $arrayref;
            $right = $arrayref;
        }
        if (ref($left) eq 'App::perl2js::Converter::Node::List') {
            my $arrayref = bless +{
                data => $left,
            }, 'App::perl2js::Converter::Node::ArrayRef';
            $left->{parent} = $arrayref;
            $left = $arrayref;
        }
        $token->{data} = " = ";
    } elsif ($name eq 'DefaultOperator') {
        return App::perl2js::Converter::Node::FunctionCall->new(
            token => bless({
                data => 'default_or',
                name => 'RuntimeHelper'
            }, 'Compiler::Lexer::Token'),
            args => [ App::perl2js::Converter::Node::Branch->new(
                token => bless({
                    data => ',',
                    name => 'Comma',
                }, 'Compiler::Lexer::Token'),
                left => $left,
                right => $right,
            ) ],
        )->to_js_ast($context);
    } elsif ($name eq 'EqualEqual') {
        $token->{data} = " == ";
    } elsif ($name eq 'NotEqual') {
        $token->{data} = " != ";
    } elsif ($name eq 'Greater') {
        $token->{data} = " > ";
    } elsif ($name eq 'GreaterEqual') {
        $token->{data} = " >= ";
    } elsif ($name eq 'Less') {
        $token->{data} = " < ";
    } elsif ($name eq 'LessEqual') {
        $token->{data} = " <= ";
    } elsif ($name eq 'Or') {
        $token->{data} = " || ";
    } elsif ($name eq 'OrEqual') {
        return App::perl2js::Converter::Node::Branch->new(
            token => bless({
                name => 'Assign'
            }, 'Compiler::Lexer::Token'),
            left => $left,
            right => App::perl2js::Converter::Node::Branch->new(
                token => bless({
                    name => 'Or'
                }, 'Compiler::Lexer::Token'),
                left => $left,
                right => $right
            ),
        )->to_js_ast($context);
    } elsif ($name eq 'Pointer') {
        # if (ref($right) eq 'App::perl2js::Converter::Node::FunctionCall' &&
        #     $right->token->data eq 'new') {
        #     $token->{data} = 'new';
        # } els
        if ((ref($right) eq 'App::perl2js::Converter::Node::ArrayRef') ||
            (ref($right) eq 'App::perl2js::Converter::Node::HashRef')) {

            my $data_node = $right->data_node;
            my $key = $right->data_node;
            return App::perl2js::Node::PropertyAccessor->new(
                # token => $self->token,
                data  => $left->to_js_ast($context),
                key   => $key->to_js_ast($context),
            );
        } else {
            $token->{data} = ".";
        }
    } elsif ($name eq 'Slice') {
        return App::perl2js::Converter::Node::FunctionCall->new(
            token => bless({
                data => 'range',
                name => 'RuntimeHelper'
            }, 'Compiler::Lexer::Token'),
            args => [ App::perl2js::Converter::Node::Branch->new(
                token => bless({
                    data => ',',
                    name => 'Comma',
                }, 'Compiler::Lexer::Token'),
                left => $left,
                right => $right,
            ) ],
        )->to_js_ast($context);
    } elsif ($name eq 'StringEqual') {
        $token->{data} = " === ";
    } elsif ($name eq 'StringNotEqual') {
        $token->{data} = " !== ";
    } elsif ($name eq 'StringAdd') {
        $token->{data} = " + ";
    } elsif ($name eq 'StringAddEqual') {
        $token->{data} = " += ";
    } elsif ($name eq 'StringMul') {
        return App::perl2js::Converter::Node::FunctionCall->new(
            token => bless({
                data => 'string_multi',
                name => 'RuntimeHelper'
            }, 'Compiler::Lexer::Token'),
            args => [ App::perl2js::Converter::Node::Branch->new(
                token => bless({
                    data => ',',
                    name => 'Comma',
                }, 'Compiler::Lexer::Token'),
                left => $left,
                right => $right,
            ) ],
        )->to_js_ast($context);
    } else {
        $token->{data} = $self->cprint(ref($self) . ", " . $name . ": " . $data);
    }

    return App::perl2js::Node::Branch->new(
        token => $token,
        left  => $left->to_js_ast($context),
        right => $right->to_js_ast($context),
    );
}

1;

__END__

=pod

=head1 NAME

App::perl2js::Converter::Node::Branch

=head1 INHERITANCE

    App::perl2js::Converter::Node::Branch
    isa App::perl2js::Converter::Node

=head1 DESCRIPTION

    Branch node has two pointers of 'left' and 'right'.
    Also, this node has 'next' pointer to access next statement's node.
    This node includes token kind of 'Operator', 'Assign' and 'Comma'.

=head1 LAYOUT

     ____________________________________        _____________
    |                                    | next |             |
    |   Branch(Operator,Assign,Comma)    |----->|             |
    |____________________________________|      |_____________|
             |                   |
       left  |                   | right
             v                   v

=head2 Example

e.g.) 1 + 2 + 3; ...

                  |
        __________|__________        _________
       |                     | next |         |
       |        Add(+)       |----->|  .....  |
       |_____________________|      |_________|
           |             |
      left |             | right
    _______v_______    __v__
   |               |  |     |
   |     Add(+)    |  |  3  |
   |_______________|  |_____|
      |         |
 left |         | right
    __v__     __v__
   |     |   |     |
   |  1  |   |  2  |
   |_____|   |_____|

=head1 SEE ALSO

[App::perl2js::Converter::Node](http://search.cpan.org/perldoc?Compiler::Parser::Node)

=head1 AUTHOR

Masaaki Goshima (goccy) <goccy54@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Masaaki Goshima (goccy).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
