#!/usr/bin/env perl

# confirm the refcounts/flags are correct for
# objects returned by the XS constructor

use Modern::Perl;
use Devel::Peek;

use blib;

use Class::XSAccessor {
    constructor => 'hash_cxa',
};

use Class::XSAccessor::Array {
    constructor => 'array_cxa',
};

sub hash_normal {
    my $class = shift;
    bless { @_ }, ref($class) || $class;
}

sub array_normal {
    my $class = shift;
    bless [], ref($class) || $class;
}

{
    Dump(__PACKAGE__->hash_cxa(foo => 'bar'));
    warn $/;
    Dump(__PACKAGE__->hash_normal(foo => 'bar'));
    warn $/;
    Dump(__PACKAGE__->array_cxa());
    warn $/;
    Dump(__PACKAGE__->array_normal());
}
