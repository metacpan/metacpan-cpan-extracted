package MyApp::Model::FileSearch;
use strict;
use base qw(
    CatalystX::CRUD::Model::File
    CatalystX::CRUD::Model::Utils
);
use MyApp::File;
__PACKAGE__->config( object_class => 'MyApp::File' );
use mro 'c3';

sub make_query {
    my ($self) = @_;
    my $q = $self->make_sql_query( $self->context->controller->form_fields );

    # we test $q in 04-query.t
    $self->context->stash( query => $q );

    # but File model expects a sub ref
    return $self->next::method;
}

1;

