package Cron::Toolkit::Tree::Visitor;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless { result => '', %args }, $class;
}

sub visit {
    my ($self, $node, @child_results) = @_;
    # Override in subclasses
    return $self->{result};
}

sub result {
    my ($self) = @_;
    return $self->{result};
}

1;
