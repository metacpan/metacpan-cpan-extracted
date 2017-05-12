#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;
use Audio::LADSPA;
use strict;
require "t/util.pl";

SKIP: {
    skip("No SDK installed",6) unless sdk_installed();
my $plug = Audio::LADSPA->plugin( id => 1043);

ok($plug->isa("Audio::LADSPA::Plugin"),"loaded delay_5s/1043");

my $object= $plug->new(44100);

ok(ref($object) and $object->isa("Audio::LADSPA::Plugin"),"object instantiation");

my $objectref2 = $object;

is("$object", "$objectref2","Object copies have same stringification");

is($object->get_uniqid,$objectref2->get_uniqid,"Object copies have same uniqids");

$objectref2 = $plug->new(44100);

ok("$object" ne "$objectref2","Different objects have different stringification");

ok($object->get_uniqid ne $objectref2->get_uniqid,"Session ids differ for different objects");
}
