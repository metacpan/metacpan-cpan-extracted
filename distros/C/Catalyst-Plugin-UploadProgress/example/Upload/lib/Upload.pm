package # hide from PAUSE
    Upload;

use strict;
use Catalyst;

our $VERSION = '0.01';

Upload->config( 
    name => 'Upload',
);

Upload->setup( qw/-Debug
                  Static::Simple
                  Cache::FastMmap
                  UploadProgress
                  / );

sub default : Private {
    my ( $self, $c ) = @_;

    $c->res->redirect( $c->uri_for('/upload') );
}

sub end : Private {
    my ( $self, $c ) = @_;
    
    return 1 if $c->res->status =~ /^3\d\d$/;
    return 1 if $c->res->body;
    $c->res->content_type( 'text/html; charset=utf-8' ) 
        unless ( $c->res->content_type );    

    $c->forward( $c->view('TT') ) unless $c->response->body;
    die if $c->debug && $c->req->params->{die};
}

1;
