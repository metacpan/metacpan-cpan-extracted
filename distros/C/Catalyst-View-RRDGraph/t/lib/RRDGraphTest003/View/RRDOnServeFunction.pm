package RRDGraphTest003::View::RRDOnServeFunction;

use strict;
use base 'Catalyst::View::RRDGraph';

__PACKAGE__->config(
  'ON_ERROR_SERVE' => sub {
      my ($self, $c, $error) = @_;

      $c->res->body("CUSTOM BODY: $error");
  }
);

1;
