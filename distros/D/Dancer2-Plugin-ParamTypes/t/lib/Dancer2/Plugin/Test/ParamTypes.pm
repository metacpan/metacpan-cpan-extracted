package Dancer2::Plugin::Test::ParamTypes;
use strict;
use warnings;
use Dancer2::Plugin;

extends('Dancer2::Plugin::ParamTypes');
plugin_keywords('with_types');

sub with_types {
    my $self = shift;
    return $self->SUPER::with_types(@_);
}

sub BUILD {
    my $self = shift;
    $self->register_type_check(
        'Int' => sub { Scalar::Util::looks_like_number( $_[0] ) },
    );
}

1;
