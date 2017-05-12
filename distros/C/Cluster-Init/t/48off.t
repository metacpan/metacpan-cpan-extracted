#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 6 }

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

`echo 'offgrp:off1:1:once:echo \$\$ > t/out; sleep 30' > t/cltab`;
$init->tell("offgrp",1);
ok(waitstat($init,"offgrp",1,"DONE"));
ok(lines(),1);
my $pid=lastline();
ok(kill(0,$pid),1);
`echo 'offgrp:off1:1:off:echo \$\$ > t/out; sleep 30' > t/cltab`;
$init->tell("offgrp",1);
sleep 1;
my $pidb=lastline();
ok($pidb,$pid);
# system("ps -eaf | tail");
ok(kill(0,$pid),0);
# `cp t/cltab.master t/cltab`;

$init->shutdown();

ok(1);
