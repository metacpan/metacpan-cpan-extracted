#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib ( "$FindBin::Bin/lib", "$FindBin::Bin/../lib" );

use Catalyst::Test 'MockApp';
use Test::More;

BEGIN {
  eval "use Test::Log4perl;";
  if ($@) {
    plan skip_all => 'Test::Log4perl required for testing logging';
  } else {
    plan tests => 2;
  }
}

my $tlogger = Test::Log4perl->get_logger("MockApp.Controller.Root");
Log::Log4perl->get_logger("MockApp");

TODO: {
  local $TODO = 'First request with get_logger in root category fails';
  Test::Log4perl->start();
  $tlogger->warn ("root/foo");
  get('/foo');
  Test::Log4perl->end('Got all log messages');
}

Test::Log4perl->start();
$tlogger->warn ("root/foo");
get('/foo');
Test::Log4perl->end('The second request send all log messages');


