package Chloro::Trait::Role;
BEGIN {
  $Chloro::Trait::Role::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

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
