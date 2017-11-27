package Chloro::Trait::Role;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose::Role;

with 'Chloro::Role::Trait::HasFormComponents';

sub fields {
    my $self = shift;

    return $self->local_fields();
}

sub groups {
    my $self = shift;

    return $self->local_groups();
}

sub composition_class_roles {
    return 'Chloro::Trait::Role::Composite';
}

1;
