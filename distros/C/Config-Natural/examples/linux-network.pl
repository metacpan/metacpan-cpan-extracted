#!/usr/bin/perl
# 
# This example shows you that Config::Natural can be also used to 
# read configuration used by shell scripts. Here we read those 
# found in the /etc/sysconfig/ directory related to the network 
# configuration. 
# 
use strict;
use Config::Natural;

my $network = new Config::Natural { quiet => 1 };
eval {
  $network->read_source('/etc/sysconfig/network');
  $network->param({GATEWAYDEV => 'eth0'}) unless $network->param('GATEWAYDEV');
  $network->read_source('/etc/sysconfig/network-scripts/ifcfg-' . $network->param('GATEWAYDEV'));
};
print <<'' and exit if $@;
Sorry but this example expects to find RedHat-like configuration 
files in /etc/sysconfig (particularly the network related files, 
as it is the goal of this eaxmple). 

print <<"NETWORK";
Okay, I'll make some guess so don't beat me if I'm wrong. 

This machine, called "@{[ $network->param('HOSTNAME') ]}", @{[ $network->param('FORWARD_IPV4') eq 'true' ? "seems" : "doesn't seem" ]} to be a router.
Its main IP address is @{[ $network->param('IPADDR') ]}
Its default gateway is @{[ $network->param('GATEWAY') ]}, using the @{[ $network->param('GATEWAYDEV') ]} interface. 
NETWORK
