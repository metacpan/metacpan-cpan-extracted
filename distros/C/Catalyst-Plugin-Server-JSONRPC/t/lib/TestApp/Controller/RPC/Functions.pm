package TestApp::Controller::RPC::Functions;

use strict;
use base 'Catalyst::Controller';


### special catalyst subs
sub begin : Private { 
    my( $self, $c, @args ) = @_;
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
sub echo_plain : JSONRPCLocal {
    my ($self, $c, @args) = @_;
    $c->stash->{'jsonrpc'} = 'echo_plain';
}

sub echo_plain_stash : JSONRPCLocal {
    my ($self, $c, @args) = @_;
    $c->stash->{'function'} = 'echo_plain_stash';
}



sub echo_path : JSONRPCPath('/rpc/functions/echo/path') {
    my ($self, $c, @args) = @_;
    $c->stash->{'jsonrpc'} = 'echo_path';
}

sub echo_path_stash : JSONRPCPath('/rpc/functions/echo/path/stash') {
    my ($self, $c, @args) = @_;
    $c->stash->{'function'} = 'echo_path_stash';
}



sub echo_regex : JSONRPCRegex('regex$') {
    my ($self, $c, @args) = @_;
    $c->stash->{'jsonrpc'} = 'echo_regex';
}

sub echo_regex_stash : JSONRPCRegex('regex.stash$') {
    my ($self, $c, @args) = @_;
    $c->stash->{'function'} = 'echo_regex_stash';
}


sub echo_fault : JSONRPCLocal {
    my ($self, $c, @args) = @_;
    $c->server->jsonrpc->config->show_errors( 1 );
    $c->req->jsonrpc->error ( 101, 'echo_fault' );
}


### shouldn't be called
sub echo_no_remote { };


1;
