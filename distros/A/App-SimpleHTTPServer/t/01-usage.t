#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;

require_ok( 'App::SimpleHTTPServer' );

no warnings 'once';

$App::SimpleHTTPServer::TESTING = 1;
App::SimpleHTTPServer->import();

my $t = Test::Mojo->new();
$t->get_ok('/')->
  status_is(200);

done_testing;
