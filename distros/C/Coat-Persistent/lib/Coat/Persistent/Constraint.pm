package Coat::Persistent::Constraint;

use strict;
use warnings;

# Singleton for storing constraints
my $REGISTRY = {};

sub add_constraint {
    my ($class, $constraint, $caller, $attribute, $value) = @_;
    $REGISTRY->{$constraint}{$caller}{$attribute} = $value;
}

sub get_constraint {
    my ($class, $constraint, $caller, $attribute) = @_;
    $REGISTRY->{$constraint}{$caller}{$attribute} || 0;
}

sub remove_constraint {
    my ($class, $constraint, $caller, $attribute) = @_;
    delete $REGISTRY->{$constraint}{$caller}{$attribute};
}

sub list_constraints {
    my ($class, $constraint, $caller) = @_;
    keys %{ $REGISTRY->{$constraint}{$caller} };
}

1;
