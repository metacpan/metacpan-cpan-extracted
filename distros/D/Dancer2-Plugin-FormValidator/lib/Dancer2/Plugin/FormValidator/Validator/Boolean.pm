package Dancer2::Plugin::FormValidator::Validator::Boolean;

use strict;
use warnings;

use Moo;
use utf8;
use List::Util qw(any);
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must be boolean',
        ru => '%s должно иметь логическое значение',
        de => '%s muss boolesch sein',
    };
}

sub validate {
    my ($self, $field, $input) = @_;

    if ($self->_field_defined_and_non_empty($field, $input)) {
        return any { $input->{$field} eq $_ } qw(0 1);
    }

    return 1;
}

1;
