package Dancer2::Plugin::FormValidator::Extension::Password::Hard;

use Moo;
use utf8;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must be minimum 8 characters long and contain at least one uppercase letter, one lowercase letter, one number and a special character',
        ru => '%s должен иметь длину не менее 8 символов и состоять хотя бы из одной заглавной буквы, строчной буквы, числа и специального символа',
        de => '%s muss mindestens 8 Zeichen lang sein und mindestens einen Großbuchstaben, einen Kleinbuchstaben, eine Ziffer und ein Sonderzeichen enthalten',
    };
}

sub validate {
    my ($self, $field, $input) = @_;

    if (exists $input->{$field}) {
        return $input->{$field} =~ /^(?=.*[a-z])(?=.*[A-Z])(?=.*[\@\$!%*#?&])[A-Za-z\d\@\$!%*#?&]{8,}$/;
    }

    return 1;
}

1;
