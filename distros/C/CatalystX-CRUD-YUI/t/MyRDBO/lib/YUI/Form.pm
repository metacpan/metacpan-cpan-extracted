package YUI::Form;
use strict;

use Carp;
use base qw( Rose::HTMLx::Form::Related::RDBO );

sub init_metadata {
    my $self = shift;
    return $self->metadata_class->new(
        form              => $self,
        controller_prefix => 'CRUD',
    );
}

sub init_app_class { 'MyRDBO' }

1;
