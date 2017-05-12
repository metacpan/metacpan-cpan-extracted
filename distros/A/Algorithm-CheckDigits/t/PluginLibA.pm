# vim: set ts=4 sw=4 tw=78 si et:
package PluginLibA;

use strict;
use warnings;

use Algorithm::CheckDigits;

# This module inherits from Algorithm::CheckDigits end reexports the function
# CheckDigits() so the user of this module does not need to explicitely
# 'use Algorithm::CheckDigits;'.

our @EXPORT = qw(CheckDigits);
our @ISA = qw(Algorithm::CheckDigits);

# These variables store the keys under which the variants of the algorithm in
# this module are registered with Algorithm::CheckDigits. They must be made
# publicly accessible for the user of this module.

our $meth1 = Algorithm::CheckDigits::plug_in('PluginLibA', 'returns 1', 'pla');
our $meth2 = Algorithm::CheckDigits::plug_in('PluginLibA', 'returns 2', 'pla');

# It's possible to use the -> notation to access the plug_in() function.

our $meth3 = Algorithm::CheckDigits->plug_in('PluginLibA', 'returns 3', 'pla');

# Since this module provides variants of the algorithm it stores the key used
# to create the instance, which is given as the first argument after the class
# name.

sub new {
    my $proto = shift;
    my $type  = shift;
    my $class = ref($proto) || $proto;
    my $self  = bless( {}, $class );
    $self->{type} = lc($type);
    return $self;
}    # new()

# This is just one example on how to use the registration keys returned by
# Algorithm::CheckDigits::plug_in().

my %methods = (
    $meth1 => 1,
    $meth2 => 2,
    $meth3 => 3,
);

sub is_valid {
    my ($self,$number) = @_;

    return $methods{$self->{type}} == $number;
}

sub complete {
    my ($self) = @_;

    return $methods{$self->{type}};
}

sub basenumber {
    my ($self) = @_;

    return $methods{$self->{type}};
}

sub checkdigit {
    my ($self) = @_;

    return $methods{$self->{type}};
}

1;
