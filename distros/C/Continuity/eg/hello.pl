#!/usr/bin/perl

use lib '../lib';
use strict;
use warnings;
use Continuity;

my $server = new Continuity(
  path_session => 1,
  port => 8080
);

$server->loop;

sub main {
  my $request = shift;

  # must do a substr to chop the leading '/'
  my $name = substr($request->{request}->url->path, 1) || 'World';

  $request->print("Hello, $name!");
  $request->next;

  $name = substr($request->{request}->url->path, 1) || 'World';
  $request->print("Hello to you too, $name!");
}

