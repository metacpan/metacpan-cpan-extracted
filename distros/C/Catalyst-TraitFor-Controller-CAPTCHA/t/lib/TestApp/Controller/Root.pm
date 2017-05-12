package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Catalyst::TraitFor::Controller::CAPTCHA';

__PACKAGE__->config->{namespace} = '';

sub default :Path { 
    my ( $self, $c ) = @_; 
    $c->forward('generate_captcha');
} 

sub check : Local : Args(1) {
    my ($self, $c , $posted_string) = @_;
    if ( $c->forward('validate_captcha',[$posted_string]) ) {
        $c->res->body( 'OK' );
    }
    else {
        $c->res->body( 'FAIL');
    }
}

1;
