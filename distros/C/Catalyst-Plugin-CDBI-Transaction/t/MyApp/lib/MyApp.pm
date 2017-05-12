package MyApp;

use strict;
use Catalyst qw/CDBI::Transaction/;
use YAML ();

our $VERSION = '0.01';

MyApp->config( name => 'MyApp' );
MyApp->config( YAML::LoadFile( MyApp->config->{home} . '/../../MyApp.yml' ) );

MyApp->setup;

sub default : Private {
    my ( $self, $c ) = @_;
    $c->stash->{output} = 'Congratulations, MyApp is on Catalyst!';
}

sub end : Private { 
    my ( $self, $c ) = @_;
    
    $c->res->output( $c->stash->{output} || '' ) unless $c->res->output;
}

1;
