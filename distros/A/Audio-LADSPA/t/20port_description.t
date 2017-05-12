#!/usr/bin/perl -w
use strict;

use Test::More tests => 16;
use Audio::LADSPA;
require "t/util.pl";

use strict;
SKIP: {
    skip("No SDK installed",16) unless sdk_installed();
my $plug = Audio::LADSPA->plugin( id => 1043);

ok($plug->isa("Audio::LADSPA::Plugin"),"loaded delay_5s/1043");

my @ports = $plug->ports;

ok(@ports == 4,"number of ports");

is($plug->port_name(0),"Delay (Seconds)","port 0 name");
is($plug->port_name(1),"Dry/Wet Balance","port 1 name");

is($plug->port2index("Delay (Seconds)"),0,"port number 0");
is($plug->port2index("Dry/Wet Balance"),1,"port number 1");
is($plug->upper_bound(0),5,"upper_bound");

use_ok('Audio::LADSPA::Plugin::Sequencer4');

is(Audio::LADSPA::Plugin::Sequencer4->port_name(0),"Run/Step","perl port name");
is(Audio::LADSPA::Plugin::Sequencer4->port2index("Run/Step"),0,"perl port number 0");

ok(defined($plug->lower_bound(0)),"lower_bound defined");

is($plug->lower_bound(0),0,"lower_bound value");

ok($plug->is_input(0),"is_input");
ok(! $plug->is_input(3),"is_input 2");

ok($plug->is_control(0),"data_type 1");
ok(!$plug->is_control(3),"data_type 2");
}
