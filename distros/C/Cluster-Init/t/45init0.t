#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 5 }

use Cluster::Init;

my %parms = (
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



`cat /dev/null > t/out`;
ok(lines(),0);
$init->tell("pidgrp",1);
sleep 1;
ok(lines(),1);
my $pid=lastline();
$init->tell("pidgrp",0);
sleep 3;
my $pide=lastline();
ok($pid,$pide);
sleep 10;
my $pidf=lastline();
ok($pide,$pidf);

$init->shutdown();

ok(1);
