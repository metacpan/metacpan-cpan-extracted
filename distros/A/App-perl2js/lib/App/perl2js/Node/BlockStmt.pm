package App::perl2js::Node::BlockStmt;

use strict;
use warnings;

use parent qw(App::perl2js::Node);

sub new {
    my ($class, %args) = @_;
    $args{statements} ||= [];
    return bless \%args, $class;
}

sub statements {
    my ($self, $statements) = @_;
    if ($statements) {
        $self->{statements} = $statements;
    } else {
        return $self->{statements};
    }
}

sub push_statement {
    my ($self, $statement) = @_;
    push @{$self->{statements}}, $statement;
}

sub sentences_to_javascript {
    my ($self, $depth, $sentences) = @_;
    return (
        (join "", map {
            $self->indent($depth),
            join('', $_->to_javascript($depth)),
            ($_->isa('App::perl2js::Node::BlockStmt') ? "\n" : ";\n"),
         } @{$sentences || $self->statements}),
    );
}

1;
