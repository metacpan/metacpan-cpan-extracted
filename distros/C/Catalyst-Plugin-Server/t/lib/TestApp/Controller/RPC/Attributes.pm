package TestApp::Controller::RPC::Attributes;

use strict;
use base 'Catalyst::Controller';


### special catalyst subs
sub rpconly : XMLRPCPath('/rpc/only') {
    my ($self, $c) = @_;
    $c->stash->{xmlrpconly} = 1;
    $c->res->output('rpconly');
}

sub webonly : Path('/web/only') {
    my ($self, $c) = @_;
    $c->stash->{webonly} = 1;
    $c->res->output('webonly');
}

sub webandrpc : Path('/web/also') : XMLRPCPath('/rpc/also') {
    my ($self, $c) = @_;
    $c->stash->{webandxmlrpc} = 1;
    $c->res->output('webandrpc');


}

1;
