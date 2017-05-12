#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  MyApp::Controller::RequestClass;
  
use Moose;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' };

sub params : Local {
    my ($self, $c) = @_;
    my $body;
    for(qw(body_params query_params params)) {
        $body->{$_} = $c->req->$_;
    }
    $c->res->body(encode_json($body));
}

sub request_class : Local {
    my ($self, $c) = @_;
    $c->res->body($c->request_class);
}



1;