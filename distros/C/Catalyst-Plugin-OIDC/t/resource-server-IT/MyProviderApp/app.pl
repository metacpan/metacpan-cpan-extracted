#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Mojolicious::Lite;

# provider server routes
get('/jwks' => sub {
      my $c = shift;
      $c->render(json => {});
    });

app->start;

return app;
