package TestApp::Controller::Token;

use strict;
use warnings;
use Data::Dumper;
use base 'Catalyst::Controller::HTML::FormFu';

__PACKAGE__->config(
    { 'Controller::HTML::FormFu' => { request_token_enable => 1 } } );

sub token : Chained : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'form.tt';
}

sub form : Chained('token') : Args(0) : Form {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    $form->elements( [ { name => 'basic_form', constraint => ['Required'] }, { type => "Submit" } ] );
	$form->process($c->req);
    if ( $form->submitted_and_valid ) {
        $c->res->body("VALID");
    }
}

sub dump_session : Local {
    my ( $self, $c ) = @_;
    $c->res->body( Dumper $c->session );
}

sub count_token : Local {
	my ( $self, $c ) = @_;
	$c->res->body( scalar @{ $c->session->{__token} || [] } );
}

1;
