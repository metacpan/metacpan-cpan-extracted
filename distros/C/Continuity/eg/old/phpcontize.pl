#!/usr/bin/perl

use strict;
use lib '..';
use Continuity::Server::Simple;
use PHP::Interpreter;

my $server = Continuity::Server::Simple->new(
    port => 8081,
    new_cont_sub => \&main,
    app_path => '/app',
    debug => 3,
);

$server->loop;

sub getParsedInput {
  my $params = $server->get_request->params;
  return $params;
}

sub main {
  my $p = PHP::Interpreter->new();
  print `pwd`;
  print "hrm.\n";
  $p->include('./bleh.php');
}

1;

