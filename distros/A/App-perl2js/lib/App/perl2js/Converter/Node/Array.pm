package App::perl2js::Converter::Node::Array;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use Compiler::Lexer::Token;
use App::perl2js::Converter::Node::Nop;
use App::perl2js::Converter::Node::Leaf;

use App::perl2js::Node::PropertyAccessor;

sub idx { shift->{idx} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    my $key;
    if (ref($self->idx) eq 'App::perl2js::Converter::Node::ArrayRef') {
        $key = $self->idx->data_node;
    } else {
        $key = $self->idx;
    }
    my $data;
    if ($self->data eq '$_') {
        $data = 'arguments';
    } else {
        $data = $self->data;
    }
    return App::perl2js::Node::PropertyAccessor->new(
        token => $self->token,
        data  => App::perl2js::Converter::Node::Leaf->new(
            token => bless({
                data => $data,
                name => 'Var',
            }, 'Compiler::Lexer::Token')
        )->to_js_ast($context),
        key   => $key->to_js_ast($context),
    );
}

1;

__END__

=pod

=head1 NAME

App::perl2js::Converter::Node::Array

=head1 INHERITANCE

    App::perl2js::Converter::Node::Array
    isa App::perl2js::Converter::Node

=head1 DESCRIPTION

    This node is created to represent array's get/set accessor.
    Array node has single pointer of 'idx'.
    Also, this node has 'next' pointer to access next statement's node.

=head1 LAYOUT

     ____________        _____________
    |            | next |             |
    |   Array    |----->|             |
    |____________|      |_____________|
          |
     idx  |
          v

=head2 Example

e.g.) $array[0]; ...

               |
     __________|__________        _________
    |                     | next |         |
    |     Array($array)   |----->|  .....  |
    |_____________________|      |_________|
               |
          idx  |
        _______v_______
       |               |
       |       0       |
       |_______________|

=head1 SEE ALSO

[App::perl2js::Converter::Node](http://search.cpan.org/perldoc?Compiler::Parser::Node)

=head1 AUTHOR

Masaaki Goshima (goccy) <goccy54@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Masaaki Goshima (goccy).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
