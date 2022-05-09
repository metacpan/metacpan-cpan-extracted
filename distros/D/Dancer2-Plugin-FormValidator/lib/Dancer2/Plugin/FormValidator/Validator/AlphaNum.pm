package Dancer2::Plugin::FormValidator::Validator::AlphaNum;

use strict;
use warnings;

use Moo;
use utf8;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

use constant {
    UNICODE => 'u',
    ASCII   => 'a',
};

has encoding => (
    is      => 'rw',
    default => ASCII,
);

sub message {
    my $encoding = $_[0]->encoding;

    if ($encoding eq UNICODE) {
        return {
            en => '%s must contain only alphabetical symbols and/or numbers 0-9',
            ru => '%s должно содержать только символы алфавита или/и цифры 0-9',
            de => '%s darf nur alphabetische Symbole und/oder Zahlen 0-9 enthalten',
        };
    }

    return {
        en => '%s must contain only latin alphabetical symbols',
        ru => '%s должно содержать только символы латинского алфавита',
        de => '%s darf nur lateinische Zeichen enthalten',
    };
}

sub validate {
    my ($self, $field, $input, $encoding) = @_;

    my $regex;

    if (defined $encoding and $encoding eq UNICODE) {
        $regex = qr/^\w+$/;
        $self->encoding(UNICODE);
    }
    else {
        $regex = qr/^\w+$/a;
        $self->encoding(ASCII);
    }

    if ($self->_field_defined_and_non_empty($field, $input)) {
        return $input->{$field} =~ $regex;
    }

    return 1;
}

1;
