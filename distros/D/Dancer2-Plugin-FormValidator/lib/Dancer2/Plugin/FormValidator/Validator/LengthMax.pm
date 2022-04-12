package Dancer2::Plugin::FormValidator::Validator::LengthMax;

use Moo;
use utf8;
use Scalar::Util qw(looks_like_number);
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must be no more %d characters long',
        ru => '%s должно содержать не более %d символов',
        de => '%s kann nicht mehr als %d Zeichen enthalten',
    };
}

sub validate {
    my ($self, $field, $input, $max) = @_;

    if ($self->_field_defined_and_non_empty($field, $input)) {
        my $maybe_str = $input->{$field};

        if (looks_like_number($maybe_str)) {
            return 0;
        }
        else {
            return length($maybe_str) <= $max;
        }
    }

    return 1;
}

1;
