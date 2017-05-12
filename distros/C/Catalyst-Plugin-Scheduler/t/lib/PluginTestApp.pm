package PluginTestApp;

use strict;
use warnings;
use Catalyst;

our $VERSION = '0.01';

# reuse the other TestApp's home directory, so we have a place to write
# the scheduler.state file
PluginTestApp->config(
    name => 'PluginTestApp',
    home => "$FindBin::Bin/lib/TestApp"
);

PluginTestApp->setup( qw/Scheduler PluginTest/ );

1;
