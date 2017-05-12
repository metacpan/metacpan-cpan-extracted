package TestApp::Controller::RPC::Settings;

use strict;
use base 'Catalyst::Controller';


sub test : XMLRPC {
    my ($self, $c, @args ) = @_;
    
    my $xmlrpc = $c->req->xmlrpc;
    my %rv = (
        sub_args            => \@args,
        xmlrpc_args         => $xmlrpc->args,
        xmlrpc_params       => $xmlrpc->params,
        catalyst_args       => $c->req->args,
        catalyst_params     => $c->req->params,
        params_same         => $c->req->params  == $xmlrpc->params,
        args_same           => ($c->req->args   == $xmlrpc->args), 
        is_xmlrpc           => $xmlrpc->is_xmlrpc_request,
        method              => $xmlrpc->method,
        body                => $xmlrpc->body,
    );
    
    $c->stash->{xmlrpc} = \%rv;
}

1;
