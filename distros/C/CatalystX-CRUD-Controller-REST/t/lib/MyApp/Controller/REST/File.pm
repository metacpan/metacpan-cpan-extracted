package MyApp::Controller::REST::File;
use strict;
use base qw(
    CatalystX::CRUD::Controller::REST
);
use Carp;
use Data::Dump qw( dump );
use File::Temp;
use MyApp::Form;
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    primary_key => 'absolute',
    data_fields => [qw( file content )],
    model_name  => 'File',
    primary_key => 'file',
    default     => 'application/json',     # default response content type
);

sub fetch {
    my ( $self, $c, $id ) = @_;
    my $rt = $self->next::method( $c, $id );

    # File model requires an object to work on
    # regardless of whether we fetched one.
    if ( !$rt and $rt == 0 ) {
        my $file = $self->do_model( $c, 'new_object', file => $id );
        $file = $self->do_model( $c, 'prep_new_object', $file );
        $c->log->debug("empty file object:$file") if $c->debug;
        $c->stash( object => $file );
        delete $c->stash->{fetch_failed};
    }

    # clean up at end
    MyApp::Controller::Root->push_temp_files( $c->stash->{object} );
    return $rt;
}

sub do_search {
    my ( $self, $c, @arg ) = @_;
    $self->next::method( $c, @arg );

    #carp dump $c->stash->{results};

    for my $file ( @{ $c->stash->{results}->{results} } ) {
        $file->read;
    }
}

1;
