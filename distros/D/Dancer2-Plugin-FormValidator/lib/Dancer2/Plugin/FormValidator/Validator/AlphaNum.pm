package Dancer2::Plugin::FormValidator::Validator::AlphaNum;

use Moo;
use utf8;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must contain only alphabetical symbols and/or numbers 0-9',
        ru => '%s должно содержать только символы алфавита или/и цифры 0-9',
        de => '%s darf nur alphabetische Symbole und/oder Zahlen 0-9 enthalten',
    };
}

sub validate {
    my ($self, $field, $input) = @_;

    if (exists $input->{$field}) {
        return $input->{$field} =~ /^\w+$/;
    }

    return 1;
}

1;
