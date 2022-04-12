package Dancer2::Plugin::FormValidator::Validator::LengthMin;

use Moo;
use utf8;
use Scalar::Util qw(looks_like_number);
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must be at least %d characters long',
        ru => '%s должно содержать не менее %d символов',
        de => '%s muss mindestens %d Zeichen enthalten',
    };
}

sub validate {
    my ($self, $field, $input, $min) = @_;

    if ($self->_field_defined_and_non_empty($field, $input)) {
        my $maybe_str = $input->{$field};

        if (looks_like_number($maybe_str)) {
            return 0;
        }
        else {
            return length($maybe_str) >= $min;
        }
    }

    return 1;
}

1;
