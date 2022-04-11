package Dancer2::Plugin::FormValidator::Validator::AlphaAscii;

use Moo;
use utf8;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must contain only latin alphabetical symbols',
        ru => '%s должно содержать только символы латинского алфавита',
        de => '%s darf nur lateinische Zeichen enthalten',
    };
}

sub validate {
    my ($self, $field, $input) = @_;

    if ($self->_field_defined_and_non_empty($input->{$field})) {
        return $input->{$field} =~ /^[[:alpha:]]+$/a;
    }

    return 1;
}

1;
