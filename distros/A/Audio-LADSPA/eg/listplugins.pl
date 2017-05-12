#!/usr/bin/perl -wl
#
# this program mimicks the output of the 'listplugins' program
# as found in the ladspa_sdk
#
# for a more elaborate example, see the 'pluginfo' program
# in this directory
#
# Joost.
#

use strict;
use Audio::LADSPA;

for (Audio::LADSPA->libraries) {
    print $_->library_file,":";
    for ($_->plugins) {
	print "\t",$_->name," (",$_->id,"/",$_->label,")";
    }
}

