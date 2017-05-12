#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 11 }

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
sleep 1;
my $init = client Cluster::Init (%parms);


`cat /dev/null > t/out`;
ok(lines(),0);
$init->tell("pidgrp",1);
sleep 1;
ok(lines(),1);
my $pid=lastline();
# warn "$pid";
sleep 1;
ok(kill(9,$pid),1);
sleep 5;
ok(lines(),1);
my $newpid=lastline();
# warn "$pid, $newpid";
ok(sub{return 1 if $pid != $newpid},1);
$init->tell("pidgrp",99);
ok(waitstat($init,"pidgrp",99,"DONE"));

`cat /dev/null > t/out`;
ok(lines(),0);
warn "\nyou should see a 'respawning too rapidly' message on the next line:\n";
$init->tell("hellogrp",2);
sleep 1 while(lines() < 5);
my $lines=lines();
ok($lines>=5);
ok($lines<=10);
sleep 5;
ok(lines()==$lines);

$init->shutdown();

ok(1);
