package TestApp::Controller::Root;
use base 'Catalyst::Controller';

use strict;
use warnings;

__PACKAGE__->config->{namespace} = '';

sub index : Private {
    my ( $self, $c ) = @_;
    $c->res->body('root index');
}

sub encrypt : Global Args(1) {
    my ( $self, $c, $id ) = @_;
    my $encripted_hash = $c->encrypt_data($id);
    $c->res->body($encripted_hash);
}

sub decrypt : Global Args(1) {
    my ( $self, $c, $hashid ) = @_;
    my $decrypted_string = $c->decrypt_data($hashid);
    $c->res->body($decrypted_string);
}

sub validhash : Global Args(1) {
    my ( $self, $c, $hashid ) = @_;
    my $status = $c->is_valid_encrypt_hash($hashid);
    $c->res->body($status);
}

sub end : Private {
    my ( $self, $c ) = @_;
    return if $c->res->body;    # already have a response
}

1;