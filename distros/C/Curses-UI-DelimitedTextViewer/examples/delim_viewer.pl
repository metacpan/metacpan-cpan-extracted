#!/opt/bin/perl -w
###############################################################################
# Use the Curses::UI to create a viewer for delimited files such that the
# columns line up. Based on the editor example from the Curses::UI distribution
#
# (c) 2002 by Garth Sainio. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as perl itself.
###############################################################################

use strict;
use Curses;
use Curses::UI;

my $text = "";

# The file to display is on the command line and should be tab delimited
my $file = shift(@ARGV);
die("No file specified.\n") unless($file);

open(DATA, $file) || die("Could not open file ($file): $!\n");

my @column_width;
my @lines;

while(<DATA>) {
    $text .= $_;
}

close(DATA);

my $cui = new Curses::UI (
        -clear_on_exit => 1
);

# Create the screen for the editor.
my $screen = $cui->add(
        'screen', 'Window',
        -padtop          => 1, # leave space for the menu
        -border          => 0,
        -ipad            => 0,
);

# We add the editor widget to this screen.
my $editor = $screen->add(
        'editor', 'DelimitedTextViewer',
        -border          => 1,
        -padtop          => 0,
        -padbottom       => 3,
        -showlines       => 0,
        -sbborder        => 0,
        -vscrollbar      => 1,
        -hscrollbar      => 1,
        -showhardreturns => 0,
        -wrapping        => 0,
        -text            => $text,
        -columnScroll    => 1,
        -addBlankColumns => 1,
#        -fieldSeparator  => "*",
);

$editor->clear_binding('loose-focus');

$cui->set_binding(\&exitProg, "\cQ", "\cC");

$cui->set_binding(sub {
        my $cui = shift;
        $cui->layout;
        $cui->draw;
}, "\cL");
$editor->focus;

$cui->mainloop;


sub exitProg {
    exit(0);
}
