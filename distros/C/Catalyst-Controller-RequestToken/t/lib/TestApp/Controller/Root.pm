package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller';

# your actions replace this one
sub main :Path { $_[1]->res->body('<h1>It works</h1>') }
sub end :Private {
   my ($self, $c) = @_; 
    $c->response->content_type("text/html; charset=UTF-8"); 
    }
1;
