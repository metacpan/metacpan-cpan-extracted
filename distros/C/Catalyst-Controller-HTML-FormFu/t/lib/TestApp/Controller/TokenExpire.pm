package TestApp::Controller::TokenExpire;

use strict;
use warnings;
use Data::Dumper;
use base 'Catalyst::Controller::HTML::FormFu';

__PACKAGE__->config( {
        'Controller::HTML::FormFu' => {
            request_token_session_key     => '_token',
            request_token_enable          => 1,
            request_token_field_name      => 'token',
            request_token_expiration_time => -10
        } } );

sub tokenexpire : Chained : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'form.tt';
}

sub form : Chained('tokenexpire') : Args(0) : Form {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    $form->elements( [ { name => 'basic_form' }, { type => "Submit" } ] );
    if ( $form->submitted_and_valid ) {
        $c->res->body("VALID");
    }
}

1;
