package Dancer2::Plugin::FormValidator::Validator::Alpha;

use Moo;
use utf8;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must contain only alphabetical symbols',
        ru => '%s должно содержать только символы алфавита',
        de => '%s darf nur alphabetische Zeichen enthalten',
    };
}

sub validate {
    my ($self, $field, $input) = @_;

    if (exists $input->{$field}) {
        return $input->{$field} =~ /^[[:alpha:]]+$/;
    }

    return 1;
}

1;
