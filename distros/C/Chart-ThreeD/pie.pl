#!/usr/bin/perl -w

BEGIN { unshift @INC, "lib" }
use strict;
use Chart::ThreeD::Pie;

my $pie = new Chart::ThreeD::Pie (500, 300, "title");

$pie->add (160, '#FFAA00', 'part 1');
$pie->add (350, '#00FF66', 'part 2');
$pie->add (100, '#AA00FF', 'part 3');
$pie->add (300, '#0000FF', 'part 4');
$pie->add (300, '#DD00FF', 'part 5');
$pie->add (300, '#00DDFF', 'part 6');

$pie->limit (0);
$pie->thickness (30);
$pie->want_sort (1);
$pie->border (1);

# $pie->fgcolor ('#FF0000');
# $pie->bgcolor ('#00FFFF');

mkdir 'samples', 0755 unless -d 'samples';
my $file = 'samples/pie.gif';
open (GIF, "> $file") || die "Can't create $file";
print GIF $pie->plot->gif;
close GIF;


