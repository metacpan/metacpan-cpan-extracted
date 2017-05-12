package MyDBIC::Base::Form;
use strict;

use Carp;
use base qw( Rose::HTMLx::Form::Related::DBIC );

sub init_metadata {
    my $self  = shift;
    my $class = ref($self);
    $class =~ s/^MyDBIC::Form:://;
    return $self->metadata_class->new(
        form              => $self,
        controller_prefix => 'CRUD::Test',
        object_class      => $class,
        schema_class      => 'MyDBIC::Schema',
    );
}

sub init_app_class {'MyDBIC'}

1;
