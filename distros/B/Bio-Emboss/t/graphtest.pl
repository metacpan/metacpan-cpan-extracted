#!/usr/bin/perl

use ExtUtils::testlib;
use Bio::Emboss ":all";

# --- store script and acd file in the same directory
($thisdir = $0) =~ s:/[^/]*$::;
$thisdir = "." unless length ($thisdir);
$ENV{"EMBOSS_ACDROOT"} = $thisdir;


ajGraphInitPerl("graphtest", \@ARGV);

$graph = ajAcdGetGraphxy ("graph");

$graph->ajGraphOpenWin(-0.1,1.4,-0.1,1.1);

# --- use ajGraphLines (draw 4 lines of a rect. at once)

@x1 = (0.2, 0.8, 0.8, 0.2);
@y1 = (0.2, 0.2, 0.8, 0.8);
@x2 = @x1[1..3, 0];
@y2 = @y1[1..3, 0];

# --- pack perl arrays into C float arrays
$px1 = pack ("f*", @x1);
$py1 = pack ("f*", @y1);
$px2 = pack ("f*", @x2);
$py2 = pack ("f*", @y2);

$oldc = ajGraphSetFore (1);
ajGraphLines($px1, $py1, $px2, $py2, scalar(@x1));

# --- draw a single line(s) in an other color
ajGraphSetFore (2);
ajGraphLine($x1[0], $y1[0], $x1[2], $y1[2]);

ajGraphSetFore (3);
for($y = $y1[0]+0.1; ($y+0.01) < $y1[2]; $y += 0.1) {
    ajGraphLine($x1[0], $y, $x1[2], $y);
}


ajGraphSetFore($oldc);
if (Bio::Emboss->can("ajGraphSetCharScale")) { # newer
    ajGraphSetCharScale(0.8);
} else {
    ajGraphSetCharSize(0.8);
}
ajGraphTextStart (0.3,0.75, "This is graphtest.pl !!");

ajGraphCloseWin();

ajExit();
