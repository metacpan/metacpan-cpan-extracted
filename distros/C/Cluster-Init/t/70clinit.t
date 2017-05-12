#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 7 }

use Cluster::Init;

my %parms = (
    'cltab' => 't/cltab',
    'socket' => 't/clinit.s'
	    );

my $clinit="perl -w -I lib ./clinit -c $parms{cltab} -s $parms{socket}"; 

`cat /dev/null > t/out`;
ok(lines(),0);
unless (fork())
{
  `$clinit -d`;
  exit;
}
sleep 1;
`$clinit pidgrp 1`;
ok(clwaitstat($clinit,"pidgrp",1,"DONE"));
ok(lines(),1);
my $pid=lastline();
ok(kill(0,$pid),1);
`$clinit -k`; 
1 while -s "t/clstat";
ok(1);
my $pidh=lastline();
ok($pid,$pidh);
ok(kill(0,$pid),0);


