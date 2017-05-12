#
# This file is part of CatalystX-Test-Recorder
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyApp::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';    
__PACKAGE__->config(namespace => '');
sub foo : Local {}

sub code304 : Local {
    my ($self, $c) = @_;
    $c->response->code(304);
}

sub cookie : Local {
    my ($self, $c) = @_;
    if($c->req->cookie('cookietest')) {
        $c->res->code(404);
    } else {
        $c->res->cookies->{cookietest} = { value => 1 }; 
    }
}

sub static : Path('/static/foo') {}

1;