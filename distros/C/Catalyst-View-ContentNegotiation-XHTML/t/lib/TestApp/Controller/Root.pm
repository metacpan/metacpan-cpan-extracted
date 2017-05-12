package # Hide from PAUSE
    TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller';

sub main :Path { }

sub nothtml :Local {
  my ($self, $c) = @_;
  $c->res->content_type('application/json');
}

sub end : ActionClass('RenderView') {}

1;
