package Dancer2::Plugin::FormValidator::Processor;

use strict;
use warnings;

use Moo;
use List::Util 1.45 qw(uniqstr);
use Dancer2::Plugin::FormValidator::Validator;
use Dancer2::Plugin::FormValidator::Factory::Messages;
use Dancer2::Plugin::FormValidator::Result;
use Types::Standard qw(InstanceOf ConsumerOf);
use namespace::clean;

has input => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Input'],
    required => 1,
);

has profile => (
    is       => 'ro',
    isa      => ConsumerOf['Dancer2::Plugin::FormValidator::Role::Profile'],
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

has validator => (
    is       => 'ro',
    isa      => InstanceOf ['Dancer2::Plugin::FormValidator::Validator'],
    lazy     => 1,
    builder  => sub {
        return Dancer2::Plugin::FormValidator::Validator->new(
            config   => $_[0]->config,
            registry => $_[0]->registry,
        );
    }
);

has messages_factory => (
    is       => 'ro',
    isa      => InstanceOf ['Dancer2::Plugin::FormValidator::Factory::Messages'],
    lazy     => 1,
    builder  => sub {
        return Dancer2::Plugin::FormValidator::Factory::Messages->new(
            config   => $_[0]->config,
            registry => $_[0]->registry,
        );
    }
);

sub run {
    my ($self) = @_;

    my $profile  = $self->profile->profile;
    my $input    = $self->input->get;
    my $messages = {};

    # Run hook before.
    $profile = $self->profile->hook_before($profile, $input);

    # Now run validation.
    my ($success, $valid, $invalid) = $self->validator->validate($profile, $input);

    # If no success, build messages.
    if ($success != 1) {
        $messages = $self->_build_messages($invalid);
    }

    # Flatten $invalid array ref and leave only unique fields.
    my @invalid_fields = uniqstr map { $_->[0] } @{ $invalid };

    # Collect valid values from input.
    my $valid_input = $self->_collect_valid($valid);

    return Dancer2::Plugin::FormValidator::Result->new(
        success  => $success,
        valid    => $valid_input,
        invalid  => \@invalid_fields,
        messages => $messages,
    );
}

sub _build_messages {
    my ($self, $invalid) = @_;

    if ($self->profile->does('Dancer2::Plugin::FormValidator::Role::HasMessages')) {
        return $self->messages_factory->build($invalid, $self->profile->messages);
    }

    return $self->messages_factory->build($invalid);
}

sub _collect_valid {
    my ($self, $valid) = @_;

    my $input = $self->input->get;

    my %valid_input;
    for my $field (@ { $valid }) {
        if (exists $input->{$field}) {
            $valid_input{$field} = $input->{$field};
        }
    }

    return \%valid_input;
}

1;
