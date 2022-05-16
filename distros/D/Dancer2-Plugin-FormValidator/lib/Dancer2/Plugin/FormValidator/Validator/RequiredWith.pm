package Dancer2::Plugin::FormValidator::Validator::RequiredWith;

use strict;
use warnings;

use Moo;
use utf8;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s is required',
        ru => '%s обязательно для заполнения',
        de => '%s ist erforderlich',
    };
}

around 'stop_on_fail' => sub {
    return 1;
};

sub validate {
    my ($self, $field, $input, $field2) = @_;

    if ($self->_field_defined_and_non_empty($field2, $input)) {
        return $self->_field_defined_and_non_empty($field, $input)
    }

    return 1;
}

1;
