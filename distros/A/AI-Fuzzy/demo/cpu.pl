#!/usr/bin/perl
use strict;
use warnings;

use AI::Fuzzy;
my $f = new AI::Fuzzy::Label;

$f->addlabel("completely idle",       99,   100, 101);
$f->addlabel("very idle",       90,   95, 100);
$f->addlabel("idle",   		80,   87,  92);
$f->addlabel("somewhat idle",   40,   65,  80);
$f->addlabel("somewhat busy",   20,   45 , 60);
$f->addlabel("busy",            8,    13,  20);
$f->addlabel("very busy",        0,   5,  10);
$f->addlabel("completely busy",  -1,  0,  1);


my $count=100;

while (1) {
   open (STAT, "vmstat -n 1 $count |") or die ("can't find vmstat"); 
 
   my $cpu = <STAT>;    # headers
   $cpu = <STAT>;	    # headers

    for (1 .. $count ) {
	$cpu = <STAT>;       # read data
  	$cpu =~ s/.* (\d+)$/$1/;

	chomp $cpu;
	print "the cpu is: $cpu " . $f->label($cpu) . "\n";
    }
    close STAT;
    sleep 1;
}
