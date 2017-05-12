#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 3 }

use Cluster::Init;

my %parms = (
    'clstat' => 't/clstat',
    'cltab' => 't/cltab',
    'socket' => 't/clinit.s'
	    );

unless (fork())
{
  my $init = Cluster::Init->daemon(%parms);
  exit;
}
sleep 1;
my $init = Cluster::Init->client(%parms);

$init->tell("hellogrp","f");
ok(waitstat($init,"hellogrp","f","FAILED"));
$init->tell("hellogrp","t");
ok(waitstat($init,"hellogrp","t","PASSED"));

$init->shutdown();
ok(1);
