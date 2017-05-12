package MyApp::Controller::FileAdapter;
use strict;
use base qw( CatalystX::CRUD::Test::Controller );
use Carp;
use Data::Dump qw( dump );
use File::Temp;
use MyApp::Form;

__PACKAGE__->config(
    form_class    => 'MyApp::Form',
    form_fields   => [qw( file content )],
    model_adapter => 'CatalystX::CRUD::ModelAdapter::File',
    model_name    => 'File',
    primary_key   => 'file',
    init_form     => 'init_with_file',
    init_object   => 'file_from_form',
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

1;
