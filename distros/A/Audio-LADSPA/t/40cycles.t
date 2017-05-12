#!/usr/bin/perl -w
use strict;

use Test::More tests => 9;

BEGIN {
    use_ok('Audio::LADSPA::Network');
}
require "t/util.pl";
my $net = Audio::LADSPA::Network->new( buffer_size => 100 );
ok($net,"instantiation");

SKIP: {
    skip("No SDK installed",7) unless sdk_installed();

my $delay1 = $net->add_plugin( id => 1043);
ok($delay1,"add delay plugin 2");

my $delay2 = $net->add_plugin( id => 1043);
ok($delay2,"add delay plugin 2");

ok($net->connect($delay1,'Output',$delay2,'Input'),"normal connect");

ok(!$net->cb_connect($delay2,'Output',$delay1->get_buffer('Input')),"circular connect callback");

ok(!$net->graph->has_a_cycle,"No cycles");


ok(!$delay2->connect('Output',$delay1->get_buffer('Input')),"circular connect on plugin");

ok(!$net->connect($delay2,'Output',$delay1,'Input'),"circular connect on net");
}

