package Dancer2::Plugin::FormValidator::Registry;

use strict;
use warnings;

use Moo;
use Carp;
use Module::Load qw(autoload);
use Types::Standard qw(ConsumerOf ArrayRef HashRef);
use namespace::clean;

has extensions => (
    is        => 'ro',
    isa       => ArrayRef[ConsumerOf['Dancer2::Plugin::FormValidator::Role::Extension']],
    predicate => 1,
);

has validators => (
    is        => 'ro',
    isa       => HashRef,
    lazy      => 1,
    builder   => sub {
        my ($self) = @_;

        my %plugin_validators;

        for my $validator (keys % { $self->_validators }) {
            $plugin_validators{$validator} = {
                extension => undef,
                validator => $self->_validators->{$validator},
            };
        }

        if ($self->has_extensions) {
            for my $extension (@{ $self->extensions }) {
                my %extension_validators;

                for my $validator (keys %{ $extension->validators } ) {
                    $extension_validators{$validator} = {
                        extension => $extension,
                        validator => $extension->validators->{$validator},
                    };
                }

                %plugin_validators = (%plugin_validators, %extension_validators);
            };
        }

        return \%plugin_validators;
    }
);

sub get {
    my ($self, $name) = @_;

    if (my $validator_struct = $self->validators->{$name}) {
        my $extension = $validator_struct->{extension};
        my $class     = $validator_struct->{validator};

        autoload $class;

        my $role      = 'Dancer2::Plugin::FormValidator::Role::Validator';

        my $validator = $extension
            ? $class->new(extension => $extension)
            : $class->new;

        if (not $validator->does($role)) {
            Carp::croak("Validator: $class should implement $role\n");
        }

        return $validator;
    }

    Carp::croak("$name is not defined\n");
}

# Validators map.
sub _validators {
    return {
        accepted        => 'Dancer2::Plugin::FormValidator::Validator::Accepted',
        alpha           => 'Dancer2::Plugin::FormValidator::Validator::Alpha',
        alpha_num       => 'Dancer2::Plugin::FormValidator::Validator::AlphaNum',
        enum            => 'Dancer2::Plugin::FormValidator::Validator::Enum',
        email           => 'Dancer2::Plugin::FormValidator::Validator::Email',
        email_dns       => 'Dancer2::Plugin::FormValidator::Validator::EmailDns',
        integer         => 'Dancer2::Plugin::FormValidator::Validator::Integer',
        length_max      => 'Dancer2::Plugin::FormValidator::Validator::LengthMax',
        length_min      => 'Dancer2::Plugin::FormValidator::Validator::LengthMin',
        max             => 'Dancer2::Plugin::FormValidator::Validator::Max',
        min             => 'Dancer2::Plugin::FormValidator::Validator::Min',
        numeric         => 'Dancer2::Plugin::FormValidator::Validator::Numeric',
        required        => 'Dancer2::Plugin::FormValidator::Validator::Required',
        required_with   => 'Dancer2::Plugin::FormValidator::Validator::RequiredWith',
        same            => 'Dancer2::Plugin::FormValidator::Validator::Same',
    };
}

1;
