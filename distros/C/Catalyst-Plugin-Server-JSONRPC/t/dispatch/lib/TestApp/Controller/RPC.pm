package TestApp::Controller::RPC;

use base 'Catalyst::Controller';

### accept every jsonrpc request here
sub my_dispatcher : JSONRPCRegex('.') {
    my( $self, $c ) = @_;
    ### return the name of the method you called
    $c->stash->{'jsonrpc'} = $c->request->jsonrpc->method;
}

1;
