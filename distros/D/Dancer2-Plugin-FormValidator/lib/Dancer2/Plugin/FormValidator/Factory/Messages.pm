package Dancer2::Plugin::FormValidator::Factory::Messages;

use strict;
use warnings;

use Moo;
use Carp;
use Hash::MultiValue;
use Types::Standard qw(InstanceOf ConsumerOf);
use namespace::clean;

has config => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Config'],
    required => 1,
);

has registry => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Registry'],
    required => 1,
);

# Generates messages for each invalid field.
sub build {
    my ($self, $profile, $invalid) = @_;

    my $messages = Hash::MultiValue->new;
    my $config   = $self->config;
    my $ucfirst  = $config->ucfirst;
    my $language = $config->language;

    for my $item (@{ $invalid }) {
        my ($field, $name, $params) = @$item;

        my $validator = $self->registry->get($name);
        my $message = $self->config->messages_validators->{$name} || $validator->message;

        if ($profile->does('Dancer2::Plugin::FormValidator::Role::HasMessages')) {
            my $profile_messages = $profile->messages;

            if (ref $profile_messages eq 'HASH') {
                $message = $profile_messages->{$field}->{$name} || $message;
            }
            else {
                Carp::croak("Messages should be a HashRef\n")
            }
        }

        {
            # Cause we need this feature.
            no warnings 'redundant';

            $messages->add(
                $field,
                sprintf(
                    $message->{$language},
                    $ucfirst ? ucfirst($field) : $field,
                    split(',', $params),
                )
            );
        }
    }

    return $messages->as_hashref_multi;
}

1;