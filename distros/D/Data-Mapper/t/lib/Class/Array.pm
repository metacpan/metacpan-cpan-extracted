package t::lib::Class::Array;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless [ @_ ], $class;
}

sub as_serializable { +{ @{ shift() } } }

!!1;
