#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 4 }

use Cluster::Init;

my %parms = (
    'cltab' => 't/cltab',
    'socket' => 't/clinit.s',
    'clstat' => 't/clstat'
	    );

unless (fork())
{
  my $init = Cluster::Init->daemon (%parms);
  exit;
}

run(1);

my $init = Cluster::Init->client (%parms);

# ok($init);
# ok($init->conf('cltab'),"t/cltab");
# ok($init->conf('socket'),"t/clinit.s");

ok($init->tell("hellogrp","1"));
run(2);
ok($init->tell("hellogrp","3"));
run(2);

ok($init->shutdown(),"all groups halting");

waitdown();

ok(1);
