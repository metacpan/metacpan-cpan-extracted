use strict;
use warnings;
 
use Test::More tests => 7;
use Alien::OpenVcdiff;
 
use Text::ParseWords qw/shellwords/;
 
my @libs = shellwords( Alien::OpenVcdiff->libs );
 
ok(grep { /^-lvcdenc$/ } @libs, 'found -lvcdenc in libs');
ok(grep { /^-lvcddec$/ } @libs, 'found -lvcddec in libs');

ok(exists($Alien::OpenVcdiff::AlienLoaded{-lvcdenc}), 'AlienLoaded hash populated with -lvcdenc');
ok(-e $Alien::OpenVcdiff::AlienLoaded{-lvcdenc}, 'AlienLoaded hash of -lvcdenc points to existant file');
ok(exists($Alien::OpenVcdiff::AlienLoaded{-lvcddec}), 'AlienLoaded hash populated with -lvcddec');
ok(-e $Alien::OpenVcdiff::AlienLoaded{-lvcddec}, 'AlienLoaded hash of -lvcddec points to existant file');

ok(-x Alien::OpenVcdiff::vcdiff_binary(), 'vcdiff_binary is executable');
