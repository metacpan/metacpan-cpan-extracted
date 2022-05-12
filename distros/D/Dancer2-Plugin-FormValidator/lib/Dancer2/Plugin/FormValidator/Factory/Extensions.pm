package Dancer2::Plugin::FormValidator::Factory::Extensions;

use strict;
use warnings;

use Moo;
use Module::Load qw(autoload);
use Types::Standard qw(InstanceOf HashRef);
use namespace::clean;

has plugin => (
    is   => 'ro',
    isa  => InstanceOf['Dancer2::Plugin::FormValidator'],
);

has extensions => (
    is   => 'ro',
    isa  => HashRef,
);

sub build {
    my ($self) = @_;

    my @extensions = map {
        my $extension = $self->extensions->{$_}->{provider};
        autoload $extension;

        $extension->new(
            plugin => $self->plugin,
            config => $self->extensions->{$_},
        );
    } keys %{ $self->extensions };

    return \@extensions;
}

1;
