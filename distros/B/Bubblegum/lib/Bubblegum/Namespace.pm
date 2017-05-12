package Bubblegum::Namespace;

use 5.10.0;

use strict;
use utf8::all;
use warnings;

our $VERSION = '0.45'; # VERSION

our $DefaultTypes = {
    ARRAY     => 'Bubblegum::Object::Array',
    CODE      => 'Bubblegum::Object::Code',
    FLOAT     => 'Bubblegum::Object::Float',
    HASH      => 'Bubblegum::Object::Hash',
    INTEGER   => 'Bubblegum::Object::Integer',
    NUMBER    => 'Bubblegum::Object::Number',
    SCALAR    => 'Bubblegum::Object::Scalar',
    STRING    => 'Bubblegum::Object::String',
    UNDEF     => 'Bubblegum::Object::Undef',
    UNIVERSAL => 'Bubblegum::Object::Universal',
};

our $ExtendedTypes = {
    %$DefaultTypes => (
        INSTANCE => 'Bubblegum::Object::Instance',
        WRAPPER  => 'Bubblegum::Wrapper'
    ),
};

sub import {
    my $class = shift;
    my %args  = ((@_ == 1) &&
        'HASH' eq ref $_[0]) ? %{shift()} : @_;

    for my $type (keys %args) {
        my $class = $args{$type};
        $type = uc $type;
        if (exists $$ExtendedTypes{$type}) {
            $$ExtendedTypes{$type} = $class // $$DefaultTypes{$type};
            eval "use $class" if $class;
        }
    }

    return $class;
}

1;
