#!/usr/bin/perl 

use strict;
use warnings;

use Curses::UI::Mousehandler::GPM;

if (gpm_enable) {
    print "Succesfully enabled GPM mouse events\n";
} else {
    print "Couldn't enable GPM mouse events\n";
}

while (1) {
    my $MEVENT = gpm_get_mouse_event();
    if ($MEVENT) {
#	print "$MEVENT\n";
	my ($id, $x, $y, $z, $bstate) = unpack("sx2i3l", $MEVENT);
	my %MEVENT = (
		      -id     => $id,
		      -x      => $x,
		      -y      => $y,
		      -bstate => $bstate
		      );
	print "Got mouse event at $x,$y\n";
    } 
}
