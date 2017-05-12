package App::perl2js::Node::File;

use strict;
use warnings;
use parent qw(App::perl2js::Node::BlockStmt);

use App::perl2js::Node::Nop;

sub new {
    my ($class, %args) = @_;
    $args{imports} ||= [];
    $args{statements} ||= [];
    return bless \%args, $class;
}

sub imports {
    my ($self) = @_;
    return $self->{imports};
}

sub push_import {
    my ($self, $import) = @_;
    push @{$self->{imports}}, $import;
}

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        (join '', map {
            join('', $_->to_javascript($depth)),
            ($_->isa('App::perl2js::Node::BlockStmt') ? "\n" : ";\n"),
         } @{$self->imports}),
        (join "", map {
            join('', $_->to_javascript($depth)),
            ($_->isa('App::perl2js::Node::BlockStmt') ? "\n" : ";\n"),
         } @{$self->statements}),
    );
}

1;
