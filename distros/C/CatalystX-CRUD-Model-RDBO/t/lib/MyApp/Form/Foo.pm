package MyApp::Form::Foo;
use strict;
use base qw( CatalystX::CRUD::Test::Form );

sub foo_from_form {
    my $self = shift;
    return $self->SUPER::object_from_form(@_);
}

sub init_with_foo {
    my $self = shift;
    return $self->SUPER::init_with_object(@_);
}

1;
