package TestApp::Controller::RPC::Functions;

use strict;
use base 'Catalyst::Controller';


### special catalyst subs
sub begin : Private { 
    my( $self, $c, %args ) = @_;
    $c->stash->{begin} = 1;
    #$c->stash->{input} = $args{input};
}

sub end : Private { 
    my( $self, $c ) = @_;
    $c->stash->{end} = 1;
}

sub auto : Private { 
    my( $self, $c ) = @_;
    $c->stash->{auto} = 1;
}


### our remote subs
sub echo_plain : XMLRPCLocal {
    my ($self, $c, %args) = @_;
    $c->stash->{'xmlrpc'} = 'echo_plain';
}

sub echo_plain_stash : XMLRPCLocal {
    my ($self, $c, %args) = @_;
    $c->stash->{'function'} = 'echo_plain_stash';
}

sub echo_unicode: XMLRPCLocal {
    my ($self, $c, %args) = @_;
    $c->stash->{'xmlrpc'} = '私はクリスです'
}

sub echo_path : XMLRPCPath('/rpc/functions/echo/path') {
    my ($self, $c, %args) = @_;
    $c->stash->{'xmlrpc'} = 'echo_path';
}

sub echo_path_stash : XMLRPCPath('/rpc/functions/echo/path/stash') {
    my ($self, $c, %args) = @_;
    $c->stash->{'function'} = 'echo_path_stash';
}



sub echo_regex : XMLRPCRegex('regex$') {
    my ($self, $c, %args) = @_;
    $c->stash->{'xmlrpc'} = 'echo_regex';
}

sub echo_regex_stash : XMLRPCRegex('regex.stash$') {
    my ($self, $c, %args) = @_;
    $c->stash->{'function'} = 'echo_regex_stash';
}


sub echo_fault : XMLRPCLocal {
    my ($self, $c, %args) = @_;
    $c->server->xmlrpc->config->show_errors( 1 );
    $c->req->xmlrpc->error ( 101, 'echo_fault' );
}


### shouldn't be called
sub echo_no_remote { };


1;
