package MyCRUD::Form;
use strict;
use warnings;
use base qw( Rose::HTML::Form );

sub build_form {
    my $self = shift;

    $self->add_fields( submit_button => 'submit' );

    $self->SUPER::build_form(@_);

}

1;
