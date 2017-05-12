#!/usr/bin/perl -w
use strict;

use Test::More tests => 11;
use Audio::LADSPA;
use strict;

require "t/util.pl";

SKIP: {
    skip("No SDK installed",11) unless sdk_installed();

my $plug = Audio::LADSPA->plugin( id => 1043);

ok($plug->isa("Audio::LADSPA::Plugin"),"loaded delay_5s/1043");

is($plug->id,"1043","id");

is($plug->label,"delay_5s","label");

is($plug->copyright,"None","copyright");

ok(!$plug->is_realtime,"is_realtime");


ok($plug->has_run,"has_run");

ok(!$plug->has_run_adding,"has_run_adding");

ok($plug->has_activate,"has_activate");

ok(!$plug->has_deactivate,"has_deactivate");

is ($plug->default('Dry/Wet Balance'),'middle',"default");

is ($plug->default_value('Dry/Wet Balance'),0.5,"default_value");

}
