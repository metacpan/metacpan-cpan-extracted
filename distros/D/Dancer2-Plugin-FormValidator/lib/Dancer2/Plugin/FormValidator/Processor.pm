package Dancer2::Plugin::FormValidator::Processor;

use strict;
use warnings;

use Moo;
use List::Util 1.45 qw(uniqstr);
use Hash::MultiValue;
use Dancer2::Plugin::FormValidator::Result;
use Types::Standard qw(InstanceOf ConsumerOf HashRef);
use namespace::clean;

has input => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

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

has validator_profile => (
    is       => 'ro',
    isa      => ConsumerOf['Dancer2::Plugin::FormValidator::Role::Profile'],
    required => 1,
);

sub result {
    my ($self)   = @_;

    my $messages = {};

    my ($success, $valid, $invalid) = $self->_validate;

    if ($success != 1) {
        $messages = $self->_messages($invalid);
    }

    # Flatten $invalid array ref and leave only unique fields.
    my @invalid_fields = uniqstr map { $_->[0] } @{ $invalid };

    # Collect valid values from input.
    my %valid_input;
    for my $field (@ { $valid }) {
        $valid_input{$field} = $self->input->{$field};
    }

    return Dancer2::Plugin::FormValidator::Result->new(
        success  => $success,
        valid    => \%valid_input,
        invalid  => \@invalid_fields,
        messages => $messages,
    );
}

# Apply validators to each fields.
# Collect valid and invalid fields.
sub _validate {
    my ($self)  = @_;

    my $success = 0;
    my %profile = %{ $self->validator_profile->profile };
    my $is_valid;
    my @valid;
    my @invalid;

    for my $field (keys %profile) {
        $is_valid = 1;
        my @validators = @{ $profile{$field} };

        for my $validator_declaration (@validators) {
            if (my ($name, $params) = $self->_split_validator_declaration($validator_declaration)) {
                my $validator = $self->registry->get($name);

                if (not $validator->validate($field, $self->input, split(',', $params))) {
                    push @invalid, [ $field, $name, $params ];
                    $is_valid = 0;
                }

                if (!$is_valid && $validator->stop_on_fail) {
                    last;
                }
            }
        }

        if ($is_valid == 1) {
            push @valid, $field;
        }
    }

    if (not @invalid) {
        $success = 1;
    }

    return ($success, \@valid, \@invalid)
}

# Because validator signatures could be validator:params, we need to split it.
sub _split_validator_declaration {
    return ($_[1] =~ /([^:]+):?(.*)/);
}

# Generates messages for each invalid field.
sub _messages {
    my ($self, $invalid) = @_;

    my $messages = Hash::MultiValue->new;
    my $config   = $self->config;
    my $ucfirst  = $config->ucfirst;
    my $language = $config->language;
    my $profile  = $self->validator_profile;

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
