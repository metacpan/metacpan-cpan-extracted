package MyApp::Controller::File;
use strict;
use base qw( CatalystX::CRUD::Test::Controller );
use Carp;
use Data::Dump qw( dump );
use File::Temp;
use MyApp::Form;

__PACKAGE__->config(
    form_class            => 'MyApp::Form',
    form_fields           => [qw( file content )],
    model_name            => 'File',
    primary_key           => 'file',
    init_form             => 'init_with_file',
    init_object           => 'file_from_form',
    view_on_single_result => 1,
);

sub fetch : Chained('/') PathPrefix CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    eval { $self->next::method( $c, $id ); };
    if ($@) {

        #$c->log->error($@) if $c->debug;
        if ( $@ =~ m/^No such File/ ) {
            my $file = $self->do_model( $c, 'new_object', file => $id );
            $file = $self->do_model( $c, 'prep_new_object', $file );
            $c->log->debug("empty file object:$file") if $c->debug;
            $c->stash( object => $file );
        }
        else {
            # re-throw
            $self->throw_error($@);
        }
    }
}

# test the view_on_single_result method
# search for a file where we know there is only one
# and then check for a redirect response code

sub do_search {

    my ( $self, $c, @arg ) = @_;

    $self->config->{view_on_single_result} = 1;

    my $tmpf = File::Temp->new;

    my $file = $c->model( $self->model_name )
        ->new_object( file => $tmpf->filename );

    if ( my $uri = $self->uri_for_view_on_single_result( $c, [$file] ) ) {
        $c->response->redirect($uri);
        return;
    }

    $self->throw_error("view_on_single_result failed");

}

1;
