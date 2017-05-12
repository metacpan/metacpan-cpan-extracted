package TestApp::Controller::RPC::Errors;

use strict;
use base 'Catalyst::Controller';


### special catalyst subs
sub privateonly : Private {
    my ($self, $c) = @_;
    $c->stash->{privateonly} = 1;
}

sub localonly : Local {
    my ($self, $c) = @_;
    $c->stash->{privateonly} = 1;
}

sub remoteonly : XMLRPC {
    my ($self, $c) = @_;
    $c->stash->{remoteonly} = 1;
}

### shouldn't be called
sub echo_no_remote { };


1;
