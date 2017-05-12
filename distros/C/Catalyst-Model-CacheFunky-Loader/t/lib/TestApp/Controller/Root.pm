package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->body( $c->welcome_message );
}

sub context : Local {
    my ( $s, $c ) = @_;

    my $name = $c->model('Funky::Context')->name(); 

    if ( $name eq 'TestApp') {
        $c->res->body(1);
    }
    else {
        $c->res->body(0);
    }

}

sub date : Local {
    my ( $s, $c ) = @_;

    my $now = $c->model('Funky::Date')->now();
    sleep(1);
    my $now2 = $c->model('Funky::Date')->now();
    $c->model('Funky::Date')->delete('now');
    my $now3 = $c->model('Funky::Date')->now();

    if( $now ne $now2 ) {
        $c->res->body(0);
        return;
    }
   
    if( $now2 eq $now3 ) {
        $c->res->body(0);
        return;
    }

    $c->res->body(1);

}

1;
