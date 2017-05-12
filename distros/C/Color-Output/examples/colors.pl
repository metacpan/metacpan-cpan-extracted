#!/usr/bin/perl
################################################################################
# This example will list all the possible colors, with their index.            #
#                                                                              #
################################################################################
use Color::Output;
Color::Output::Init;

for (my($i)=0;$i<16;$i++) {
  cprint("Color=$i". (" " x (15 - length($i))) ."\x03" . $i . "Example $0, color $i\x030\n");
}
