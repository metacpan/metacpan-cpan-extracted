package Dancer2::Plugin::FormValidator::Extension::DBIC;

use Moo;

with 'Dancer2::Plugin::FormValidator::Role::Extension';

our $VERSION = '0.81';

has plugin_dbic => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return shift->plugin->app->with_plugin('Dancer2::Plugin::DBIC');
    }
);

has schema => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->plugin_dbic->schema($self->config->{database});
    }
);

sub validators {
    return {
        unique => 'Dancer2::Plugin::FormValidator::Extension::DBIC::Unique',
    };
}

1;

__END__
# ABSTRACT: Dancer2 FormValidator extension for checking field present in table row using DBIC.

=pod


=encoding UTF-8

=head1 NAME

Dancer2::Plugin::FormValidator::Extension::DBIC - Dancer2 FormValidator extension for checking fields existence in table rows.

=head1 VERSION

version 0.81

=head1 SYNOPSIS

    package Validator {
        use Moo;

        with 'Dancer2::Plugin::FormValidator::Role::Profile';

        sub profile {
            return {
                username => [ qw(required unique:User,username) ],
            };
        };
    }


=head1 DISCLAIMER

This is beta version, not stable.

=head1 DESCRIPTION

This extension provides validators database data existence for Dancer2::Plugin::FormValidator.

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
                    dbic => {
                        provider => 'Dancer2::Plugin::FormValidator::Extension::DBIC',
                        database => 'default' # DBIC database
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
                dbic:
                    provider: 'Dancer2::Plugin::FormValidator::Extension::DBIC'
                    database: 'default' # DBIC database
                    ...
    ...

=head1 Validators

=head3 unique

    unique:source,column

The field under validation must not exist within the given database source(table).

=head1 SOURCE CODE REPOSITORY

L<https://github.com/AlexP007/dancer2-plugin-formvalidator-extension-dbic|https://github.com/AlexP007/dancer2-plugin-formvalidator-extension-dbic>.

=head1 AUTHOR

Alexander Panteleev <alexpan at cpan dot org>.

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Alexander Panteleev.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
