#!/usr/bin/perl -w
use strict;
use Test::More tests => 6;

use strict;
require "t/util.pl";

BEGIN {
    use_ok('Audio::LADSPA');
}

SKIP: {
    skip("No SDK installed", 5) unless sdk_installed();
    
          ok(@Audio::LADSPA::LIBRARIES > 0,"some libraries loaded");

          is( scalar(grep { $_ eq 'Audio::LADSPA::Library::delay' } Audio::LADSPA->libraries),1,"Audio::LADSPA::Library::delay loaded");

          ok((scalar grep { $_ eq 'Audio::LADSPA::Plugin::XS::delay_5s_1043' } Audio::LADSPA->plugins) > 0,"Audio::LADSPA::Plugin::XS::delay_5s_1043 loaded"); 

          ok(Audio::LADSPA->plugin( label => 'delay_5s' )->isa("Audio::LADSPA::Plugin"),"Plugin inheritance");

          ok(Audio::LADSPA->plugin( name => 'Simple Delay Line')->isa("Audio::LADSPA::Plugin"),"Find by name");
}


