package MyForm;
use strict;
use base qw( CatalystX::CRUD::Test::Form );

sub init_with_track {
    my $self = shift;
    return $self->SUPER::init_with_object(@_);
}

sub track_from_form {
    my $self = shift;
    return $self->SUPER::object_from_form(@_);
}

1;
