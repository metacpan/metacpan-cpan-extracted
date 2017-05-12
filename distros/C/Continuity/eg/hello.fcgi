#!/usr/bin/perl
use lib '../lib';
use strict;
use warnings;

use Continuity;
use Continuity::Adapt::FCGI;
my $server = new Continuity(
  adapter => 'FCGI',
);

$server->loop;

my $c = 0;

sub main {
  my $request = shift;
STDERR->print(__FILE__, ' ', __LINE__, "\n");
  # must do a substr to chop the leading '/'
  my $name = substr($request->{request}->url->path, 1) || 'World';
  $c++;
  $request->print("Hello, $name ($c)!");
STDERR->print(__FILE__, ' ', __LINE__, "\n");
  $request->next;
STDERR->print(__FILE__, ' ', __LINE__, "\n");
  $name = substr($request->{request}->url->path, 1) || 'World';
  $request->print("Hello to you too, $name!");
STDERR->print(__FILE__, ' ', __LINE__, "\n");
}

