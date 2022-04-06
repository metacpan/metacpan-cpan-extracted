package Dancer2::Plugin::FormValidator::Extension::Password;

use Moo;

with 'Dancer2::Plugin::FormValidator::Role::Extension';

our $VERSION = '0.80';

sub validators {
    return {
        password_simple => 'Dancer2::Plugin::FormValidator::Extension::Password::Simple',
        password_robust => 'Dancer2::Plugin::FormValidator::Extension::Password::Robust',
        password_hard   => 'Dancer2::Plugin::FormValidator::Extension::Password::Hard',
    };
}

1;

__END__
# ABSTRACT: Dancer2 FormValidator extension for validating passwords.

=pod


=encoding UTF-8

=head1 NAME

Dancer2::Plugin::FormValidator::Extension::Password - Dancer2 FormValidator extension for validating passwords.


=head1 VERSION

version 0.80

=head1 SYNOPSIS

    package Validator {
        use Moo;

        with 'Dancer2::Plugin::FormValidator::Role::Profile';

        sub profile {
            return {
                email    => [qw(required email)],
                password => [qw(required password_robust)],
            };
        };
    }


=head1 DISCLAIMER

This is beta version, not stable.

=head1 DESCRIPTION

This extension provides validators for password verification for Dancer2::Plugin::FormValidator.

L<Dancer2::Plugin::FormValidator|https://metacpan.org/pod/Dancer2::Plugin::FormValidator>.

=head1 CONFIGURATION

    set plugins => {
            FormValidator => {
                session    => {
                    namespace => '_form_validator'
                },
                forms      => {
                    login => 'Validator',
                },
                extensions => {
                    password => {
                        provider => 'Dancer2::Plugin::FormValidator::Extension::Password',
                    }
                }
            },
        };

config.yml:

     ...
    plugins:
        FormValidator:
            session:
                namespace: '_form_validator'
            extensions:
                password:
                    provider: 'Dancer2::Plugin::FormValidator::Extension::Password'
                    ...
    ...

=head1 Validators

=head3 password_simple

Field must be minimum 8 characters long and contain at least one letter and one number.

=head3 password_robust

Field must be minimum 8 characters long and contain at least one letter, a number, and a special character.

=head3 password_hard

must be minimum 8 characters long and contain at least one uppercase letter, one lowercase letter, one number and a special character.

=head1 SOURCE CODE REPOSITORY

L<https://github.com/AlexP007/dancer2-plugin-formvalidator-extension-password|https://github.com/AlexP007/dancer2-plugin-formvalidator-extension-password>.

=head1 AUTHOR

Alexander Panteleev <alexpan at cpan dot org>.

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Alexander Panteleev.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
