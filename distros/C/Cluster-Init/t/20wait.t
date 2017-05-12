#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 12 }

use Cluster::Init;
# use Event;

my %parms = (
    'clstat' => 't/clstat',
    'cltab' => 't/cltab',
    'socket' => 't/clinit.s'
	    );

unless (fork())
{
  my $init = daemon Cluster::Init (%parms);
  exit;
}

run(1);

my $init = client Cluster::Init (%parms);

`cat /dev/null > t/out`;
ok(lines(),0);
$init->tell("hellogrp",1);
ok(waitstat($init,"hellogrp",1,"DONE"));
$init->tell("hellogrp","3");
ok(waitstat($init,"hellogrp",3,"STARTING"));
ok($init->status(group=>"hellogrp",level=>"3"),"STARTING");
ok(lines(),1);
ok(waitstat($init,"hellogrp",3,"DONE"));
ok(lines(),0);
$init->tell("hellogrp",1);
ok(waitstat($init,"hellogrp",1,"DONE"));
ok(lines(),1);
`cat /dev/null > t/out`;
ok(lines(),0);
$init->tell("hellogrp",1);
run(1);
ok(lines(),0);

$init->shutdown();
ok(1);
