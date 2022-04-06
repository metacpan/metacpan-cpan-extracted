package Dancer2::Plugin::FormValidator::Validator::Required;

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
    my ($self, $field, $input) = @_;

    if (exists $input->{$field} and $input->{$field} ne '') {
        return 1;
    }

    return 0;
}

1;
