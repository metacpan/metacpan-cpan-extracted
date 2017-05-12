#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 4 }

use Cluster::Init;

unless (fork())
{
  my $daemon = Cluster::Init->daemon (
      'cltab' => 't/cltab',
      'socket' => 't/clinit.s'
      );
  exit;
}

run(3);

my $client = Cluster::Init->client (
    'cltab' => 't/cltab',
    'socket' => 't/clinit.s'
			);

ok($client);
ok($client->conf('cltab'),"t/cltab");
ok($client->conf('socket'),"t/clinit.s");

$client->shutdown();

ok(1);
