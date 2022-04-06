package Dancer2::Plugin::FormValidator::Validator::Integer;

use Moo;
use utf8;
use Scalar::Util qw(looks_like_number);
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must be an integer',
        ru => '%s должно содержать целочисленное значение',
        de => '%s muss eine ganze Zahl sein',
    };
}

sub validate {
    my ($self, $field, $input) = @_;

    if (exists $input->{$field}) {
        my $maybe_int = $input->{$field};

        if (looks_like_number($maybe_int)) {
            return int($maybe_int) == $maybe_int;
        }
        else {
            return 0;
        }
    }

    return 1;
}

1;
