package Dancer2::Plugin::FormValidator::Validator::Max;

use Moo;
use utf8;
use Scalar::Util qw(looks_like_number);
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must be no more than %d',
        ru => '%s должно быть не больше %d',
        de => 'muss kleiner als %d sein',
    };
}

sub validate {
    my ($self, $field, $input, $max) = @_;

    if (exists $input->{$field}) {
        my $maybe_num = $input->{$field};

        if (looks_like_number($maybe_num)) {
            return $maybe_num <= $max;
        }
        else {
            return 0;
        }
    }

    return 1;
}

1;
