#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 3 }

`echo > t/blank`;

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
run(1);
my $init = Cluster::Init->client(%parms);

ok($init);

my $res = $init->tell("sadkjhfkdsa","1");
# run(1);
# ok($init->status(group=>"hellogrp",level=>"1"),"");
ok($res =~ /no such group/);

$init->shutdown(15);

ok(1);
