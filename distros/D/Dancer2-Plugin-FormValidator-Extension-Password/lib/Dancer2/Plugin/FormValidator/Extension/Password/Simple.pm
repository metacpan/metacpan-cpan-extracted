package Dancer2::Plugin::FormValidator::Extension::Password::Simple;

use Moo;
use utf8;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must be minimum 8 characters long and contain at least one letter and one number',
        ru => '%s должен иметь длину не менее 8 символов и состоять хотя бы из одной буквы и числа',
        de => '%s muss mindestens 8 Zeichen lang sein und mindestens einen Buchstaben und eine Zahl enthalten',
    };
}

sub validate {
    my ($self, $field, $input) = @_;

    if ($self->_field_defined_and_non_empty($field, $input)) {
        return $input->{$field} =~ /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d\@\$!%*#?&]{8,}$/;
    }

    return 1;
}

1;
