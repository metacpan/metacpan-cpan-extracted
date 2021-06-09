#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Routes::Tiny;

my %dispatch = (
  foos => sub {
    my ($cgi) = @_;
    my $method = $cgi->method;
    $cgi->render(text => "$method foos");
  },
  get_foo => sub {
    my ($cgi, $captures) = @_;
    my $id = $captures->{id};
    $cgi->render(text => "Retrieved foo $id");
  },
  put_foo => sub {
    my ($cgi, $captures) = @_;
    my $id = $captures->{id};
    $cgi->render(text => "Stored foo $id");
  },
);

cgi {
  my $cgi = $_;

  my $routes = Routes::Tiny->new;
  # /script.cgi/foo
  $routes->add_route('/foo', name => 'foos');
  # /script.cgi/foo/42
  $routes->add_route('/foo/:id', method => 'GET', name => 'get_foo');
  $routes->add_route('/foo/:id', method => 'PUT', name => 'put_foo');

  if (defined(my $match = $routes->match($cgi->path, method => $cgi->method))) {
    $dispatch{$match->name}->($cgi, $match->captures);
  } else {
    $cgi->set_response_status(404)->render(text => 'Not Found');
  }
};
