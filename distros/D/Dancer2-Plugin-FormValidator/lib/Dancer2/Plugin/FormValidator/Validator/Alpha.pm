package Dancer2::Plugin::FormValidator::Validator::Alpha;

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
    my $encoding = shift->encoding;

    if ($encoding eq UNICODE) {
        return {
            en => '%s must contain only alphabetical symbols',
            ru => '%s должно содержать только символы алфавита',
            de => '%s darf nur alphabetische Zeichen enthalten',
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
        $regex = qr/^[[:alpha:]]+$/;
        $self->encoding(UNICODE);
    }
    else {
        $regex = qr/^[[:alpha:]]+$/a;
        $self->encoding(ASCII);
    }

    if ($self->_field_defined_and_non_empty($field, $input)) {
        return $input->{$field} =~ $regex;
    }

    return 1;
}

1;
