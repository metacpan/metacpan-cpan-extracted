#!/usr/bin/env perl
use Mojolicious::Lite;

# You can spin this up when testing t/advanced in order to avoid 404s

get '/' => sub {
    my $c = shift;
    $c->render( template => 'index' );
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious real-time web framework!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
