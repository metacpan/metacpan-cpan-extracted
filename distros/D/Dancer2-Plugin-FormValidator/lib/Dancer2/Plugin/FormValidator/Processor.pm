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

has messages => (
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

    my $input    = $self->input->get;
    my $messages = {};

    my ($success, $valid, $invalid) = $self->validator->validate($self->profile, $input);

    if ($success != 1) {
        $messages = $self->messages->build($self->profile, $invalid);
    }

    # Flatten $invalid array ref and leave only unique fields.
    my @invalid_fields = uniqstr map { $_->[0] } @{ $invalid };

    # Collect valid values from input.
    my %valid_input;
    for my $field (@ { $valid }) {
        $valid_input{$field} = $input->{$field};
    }

    return Dancer2::Plugin::FormValidator::Result->new(
        success  => $success,
        valid    => \%valid_input,
        invalid  => \@invalid_fields,
        messages => $messages,
    );
}

1;
