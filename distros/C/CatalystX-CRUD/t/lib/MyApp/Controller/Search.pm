package MyApp::Controller::Search;
use strict;
use base qw( CatalystX::CRUD::Test::Controller );
use Carp;
use Data::Dump qw( dump );
use File::Temp;
use MyApp::Form;

__PACKAGE__->config(
    primary_key => 'absolute',
    form_class  => 'MyApp::Form',
    form_fields => [qw( file content )],
    model_name  => 'FileSearch',
    primary_key => 'file',
    init_form   => 'init_with_file',
    init_object => 'file_from_form',
);

sub end : Private {
    my ( $self, $c ) = @_;
    $c->log->debug( "resp status = " . $c->res->status ) if $c->debug;
    delete $c->stash->{query}->{query_obj};
    $c->res->body( Data::Dump::dump( $c->stash->{query} ) );
    1;
}

1;
