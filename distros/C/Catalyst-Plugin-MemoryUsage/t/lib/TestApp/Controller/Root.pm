package TestApp::Controller::Root;

use strict;
use warnings;

use parent 'Catalyst::Controller';

sub index : Path('/index') {
    my ( $self, $c ) = @_;

    $c->memory_usage->record( "in the middle of index" );

    $c->res->body( 'howdie' );
}


1;






