#!/usr/bin/perl
# -d:ptkdb

#
# Volume control application.
# It's a very simple application which uses Mixer.pm to control
# the sound volume. It's written to be used inside the
# FVWM FvwmButtons panel.
#
# Copyright (c) 2001 Sergey Gribov <sergey@sergey.com>
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute and modify it freely, but please leave
# this message attached to this file.
#
# Subject to terms of GNU General Public License (www.gnu.org)
#
# Last update: $Date: 2001/03/20 00:20:50 $ by $Author: sergey $
# Revision: $Revision: 1.3 $

use Tk;
use Audio::Mixer;
use strict;

$| = 1;

my $debug = 0;
my $win_h = 69;
my $win_w = 62;

Audio::Mixer::set_mixer_dev("/dev/mixer");

my $ret = Audio::Mixer::init_mixer();
die("Can't open sound mixer...") if $ret;

my @vol = Audio::Mixer::get_cval('vol');
my $volume = ($vol[0] + $vol[1]) / 2;

my $main = MainWindow->new;
$main->geometry($win_w.'x'.$win_h.'+0-0');

my $sb = $main->Scale(-orient => 'vertical', -resolution => 1,
		      -from => 100, -to => 0, -sliderlength => 10,
		      -showvalue => 0, -variable => \$volume,
		      -command => sub{change_volume();}
		      );
$sb->pack(-fill => 'y', );

MainLoop;

print "Should never end up here... :)\n";

exit;

###################################################################
sub change_volume {
  print "$volume\n" if $debug;
  Audio::Mixer::set_cval('vol', $volume);
}
