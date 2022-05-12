package Dancer2::Plugin::FormValidator::Role::Validator;

use strict;
use warnings;

use Moo::Role;
use Types::Standard qw(ConsumerOf);
use namespace::clean;

has extension => (
    is        => 'ro',
    isa       => ConsumerOf['Dancer2::Plugin::FormValidator::Role::Extension'],
    predicate => 1,
);

requires 'validate';
requires 'message';

sub stop_on_fail {
    return 0;
}

sub _field_defined_and_non_empty {
    my ($self, $field, $input) = @_;

    if (
        exists $input->{$field}
        and defined $input->{$field}
        and $input->{$field} ne ''
    ) {
        return 1;
    }

    return 0;
}

1;
