package MyApp::Controller::REST::File;
use strict;
use base qw(
    CatalystX::CRUD::REST
    CatalystX::CRUD::Test::Controller
);
use Carp;
use Data::Dump qw( dump );
use File::Temp;
use MyApp::Form;
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    primary_key => 'absolute',
    form_class  => 'MyApp::Form',
    form_fields => [qw( file content )],
    model_name  => 'File',
    primary_key => 'file',
    init_form   => 'init_with_file',
    init_object => 'file_from_form',
);

sub fetch {
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

sub do_search {
    my ( $self, $c, @arg ) = @_;
    $self->next::method( $c, @arg );

    #carp dump $c->stash->{results};

    for my $file ( @{ $c->stash->{results}->{results} } ) {
        $file->read;
    }
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->log->debug( "Body: " . $c->res->body ) if $c->debug;
    $self->next::method($c);
}

1;
