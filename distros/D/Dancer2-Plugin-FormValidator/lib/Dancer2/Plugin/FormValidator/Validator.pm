package Dancer2::Plugin::FormValidator::Validator;

use strict;
use warnings;

use Moo;
use Storable qw(dclone);
use Hash::Util qw(lock_hashref);
use Dancer2::Plugin::FormValidator::Registry;
use Dancer2::Plugin::FormValidator::Processor;
use Types::Standard qw(InstanceOf ConsumerOf HashRef ArrayRef);
use namespace::clean;

has config => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Config'],
    required => 1,
);

has extensions => (
    is       => 'ro',
    isa      => ArrayRef[ConsumerOf['Dancer2::Plugin::FormValidator::Role::Extension']],
    required => 1,
);

has input => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has validator_profile => (
    is       => 'ro',
    isa      => ConsumerOf['Dancer2::Plugin::FormValidator::Role::Profile'],
    required => 1,
);

has registry => (
    is       => 'ro',
    default  => sub {
        return Dancer2::Plugin::FormValidator::Registry->new(
            extensions => $_[0]->extensions,
        );
    }
);

sub BUILDARGS {
    my ($self, %args) = @_;

    if (my $input = $args{input}) {
        $args{input} = $self->_clone_and_lock_input($input)
    }

    return \%args;
}

sub validate {
    my ($self) = @_;

    my $processor = Dancer2::Plugin::FormValidator::Processor->new(
        input             => $self->input,
        config            => $self->config,
        registry          => $self->registry,
        validator_profile => $self->validator_profile,
    );

    return $processor->result;
}

sub _clone_and_lock_input {
    # Copy input to work with isolated HashRef.
    my $input = dclone($_[1]);

    # Lock input to prevent accidental modifying.
    return lock_hashref($input);
}

1;
