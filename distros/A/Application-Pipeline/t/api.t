#!/usr/bin/perl -T

use lib '../lib';
use strict;
use warnings;

use Test::More tests => 10;

# 1
use_ok( 'Application::Pipeline' );

# check api
# 2-10
ok( UNIVERSAL::can('Application::Pipeline',$_),"found method $_")
  foreach ( qw(
      run
      addHandler setPhases
      setPluginLocations loadPlugin loadPlugins unloadPlugins
      addServices dropServices
  ));
