#!/usr/bin/perl -w
use strict;
require "t/util.pl";
use Test::More tests => 2;
use Audio::LADSPA;

use strict;
SKIP: {
    skip("No SDK installed",2) unless sdk_installed();

my $plug = Audio::LADSPA->plugin( id => 1043);

ok($plug->isa("Audio::LADSPA::Plugin"),"loaded delay_5s/1043");

my @ports = $plug->ports;

ok(@ports == 4,"number of ports");

}
