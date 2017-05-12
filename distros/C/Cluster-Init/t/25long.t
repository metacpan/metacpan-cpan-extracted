#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 17 }

use Cluster::Init;

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
$init->tell("hellogrp","long1");
ok(waitstat($init,"hellogrp","long1","DONE"));
ok(lines(),1);
ok(lastline(),"long");
$init->tell("hellogrp","long3");
ok(waitstat($init,"hellogrp","long3","DONE"));
ok(lines(),1);
ok(lastline(),"long3");
$init->tell("hellogrp","long2");
ok(waitstat($init,"hellogrp","long2","DONE"));
ok(lines(),1);
ok(lastline(),"long");
$init->tell("hellogrp","long3");
ok(waitstat($init,"hellogrp","long3","DONE"));
ok(lines(),1);
ok(lastline(),"long3");
$init->tell("hellogrp","5");
ok(waitstat($init,"hellogrp","5","DONE"));
ok(lines(),1);
ok(lastline(),"long");

$init->shutdown();
ok(1);
