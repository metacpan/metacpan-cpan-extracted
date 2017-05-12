package TestApp::Controller::RPC::Settings;

use strict;
use base 'Catalyst::Controller';


sub test : JSONRPC {
    my ($self, $c, @args ) = @_;
    
    my $jsonrpc = $c->req->jsonrpc;
    my %rv = (
        sub_args            => \@args,
        jsonrpc_args         => $jsonrpc->args,
        jsonrpc_params       => $jsonrpc->params,
        catalyst_args       => $c->req->args,
        catalyst_params     => $c->req->params,
        params_same         => $c->req->params  == $jsonrpc->params,
        args_same           => ($c->req->args   == $jsonrpc->args), 
        is_jsonrpc           => $jsonrpc->is_jsonrpc_request,
        method              => $jsonrpc->method,
        body                => $jsonrpc->body,
    );
    
    $c->stash->{jsonrpc} = \%rv;
}

1;
