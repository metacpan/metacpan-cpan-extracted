# vim: set ts=4 sw=4 tw=78 si et:
package PluginLibB;

# This module is usable either as a plugin for Algorithm::CheckDigits or
# stand-alone. As a plugin one can create instances with the CheckDigits()
# function from Algorithm::CheckDigits. If that modulue is not available,
# it is possible to create instances with PluginLibB->new().
# See pluginlibb.t and pluginlibb-without.t for example usage.

use strict;
use warnings;

# These variables store the keys under which the variants of the algorithm in
# this module will be registered with Algorithm::CheckDigits if that module is
# available. They must be made publicly accessible for the user of this module.
#
# If there are no variations of the algorithm, it is not necessary to use such
# variables in stand-alone mode. But for usage together with
# Algorithm::CheckDigits at least one method per variant is mandatory.

our ($meth1,$meth2,$meth3);

# Since this module should work regardless of the availability of
# Algorithm::CheckDigits we have to 'eval "use Algorithm::CheckDigits";'.

eval "use Algorithm::CheckDigits";
if ($@) {
    $meth1 = 'plb1';
    $meth2 = 'plb2';
    $meth3 = 'plb3';
}
else {
    $meth1 = Algorithm::CheckDigits::plug_in('PluginLibB', 'returns 1', 'plb1');
    $meth2 = Algorithm::CheckDigits::plug_in('PluginLibB', 'returns 2', 'plb2');

    # It's possible to use the -> notation to access the plug_in() function.

    $meth3 = Algorithm::CheckDigits->plug_in('PluginLibB', 'returns 3', 'plb3');
}

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
