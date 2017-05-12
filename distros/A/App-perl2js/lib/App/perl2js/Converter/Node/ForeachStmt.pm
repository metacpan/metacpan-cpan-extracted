package App::perl2js::Converter::Node::ForeachStmt;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node::BlockStmt';

use App::perl2js::Converter::Node::Nop;

use App::perl2js::Node::ForofStmt;

sub cond { shift->{cond} // App::perl2js::Converter::Node::Nop->new; }
sub itr { shift->{itr} // App::perl2js::Converter::Node::Nop->new; }

sub to_js_ast {
    my ($self, $context) = @_;
    return App::perl2js::Node::ForofStmt->new(
        token => $self->token,
        cond  => $self->cond->to_js_ast($context),
        itr   => $self->itr->to_js_ast($context),
        statements => [ map { $_->to_js_ast($context) } @{$self->statements} ],
    );
}

1;

__END__

=pod

=head1 NAME

App::perl2js::Converter::Node::ForeachStmt

=head1 INHERITANCE

    App::perl2js::Converter::Node::ForeachStmt
    isa App::perl2js::Converter::Node

=head1 DESCRIPTION

    This node is created to represent foreach statement.
    ForeachStmt node has three pointers of 'cond', 'itr' and 'true_stmt'.
    Also, this node has 'next' pointer to access next statement's node.

=head1 LAYOUT

     _____________________________________        _____________
    |                                     | next |             |
    |             ForeachStmt             |----->|             |
    |_____________________________________|      |_____________|
           |          |             |
     cond  |      itr |   true_stmt |
           v          v             v

=head2 Example

e.g.) foreach my $itr (@array) { $itr++ }

                            |
     _______________________|________________________        _____________
    |                                                | next |             |
    |               ForeachStmt(foreach)             |----->|             |
    |________________________________________________|      |_____________|
               |            |            |
          cond |        itr |  true_stmt |
           ____v____    ____v____    ____v____
          |         |  |         |  |         |
          |   ++    |  |  $itr   |  |   ++    |
          |_________|  |_________|  |_________|
               |                          |
          expr |                     expr |
           ____v____                  ____v____
          |         |                |         |
          | @array  |                |  $itr   |
          |_________|                |_________|



=head1 SEE ALSO

[App::perl2js::Converter::Node](http://search.cpan.org/perldoc?Compiler::Parser::Node)

=head1 AUTHOR

Masaaki Goshima (goccy) <goccy54@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Masaaki Goshima (goccy).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
