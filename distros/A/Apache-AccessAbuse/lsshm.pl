#!/usr/bin/perl -wl

use IPC::Shareable;

my %NETTABLE;

#
# Copied from Writting Apache Modules sample module Apache::SpeedLimit, pg. 276
#
tie %NETTABLE, 'IPC::Shareable', 'ApAc', {create =>1, mode => 0644};

foreach my $net (keys %NETTABLE) {
  printf "%6d: %s\n", $NETTABLE{$net}, $net;
}

printf " Total: %d connections\n", scalar keys %NETTABLE;
