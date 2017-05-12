package TestApp::Controller::RPC::Regex;

use strict;
use base 'Catalyst::Controller';

### accept every xmlrpc request here
sub my_dispatcher : XMLRPCRegex('^.$') {
     my( $self, $c ) = @_;

     ### return the name of the method you called
     $c->stash->{'xmlrpc'} = $c->request->xmlrpc->method;
}

1;
