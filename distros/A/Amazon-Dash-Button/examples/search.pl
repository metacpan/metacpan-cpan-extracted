#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Amazon::Dash::Button ();

die
  "You should run this script as root. Please run:\nsudo $0 [en0|eth0|wlan0]\n"
  if $>;

my $dev = $ARGV[0] // q{wlan0};

Amazon::Dash::Button->search(

    #filter => q{arp or ( udp and ( port 67 or port 68 ) )}
    dev   => $dev,
    cache => 1
);
