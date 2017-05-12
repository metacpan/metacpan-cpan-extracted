#!/usr/bin/perl

use CNC::Cog;
use CNC::Cog::Gdcode; 
use CNC::Cog::Gcode; 

# process options. Use getopts if you like. 
my %opt; 
$opt{allowed}='p'; 
@ARGV=grep { s/^-([$opt{allowed}])//?(($opt{$1}=1)&&0):1 } @ARGV; # set options allowed in opt
grep { m/^-/ } @ARGV and die "Illegal option in @ARGV"; 

my ($g);
if ($opt{p})
{
  $g=new Gdcode("test.png",1.5,300,300);   # this uses the GD module to generate a .png file size 1950 pixels square. 
}
else
{
   my $feed=3.0;                           # feed rate for cut. 
   $g=new Gcode("test.ngc",$feed);         # and this produces gcode in the file test.ngc. 
}

$c=newcogpair Cog(1.6,7,16); # Creates a pair of meshing wheels, with teeth module 1.6 (mm) one with 7 teeth, one with 16. 
$c->{wheel}->hole(0.16); 
$c->{wheel}->cutset(0.0625,4,-0.015); # cuttersize, passes, passdepth 

$c->{wheel}->trepan(5,0.2,0.175,0.35,0.05,1.0,0.05);
#		$spoken, # number of spokes
#		$wos,	 # total width of spokes
#		$bsf,    # boss radius in inches
#		$rsf,    # rim size factor as proportion of pitch radius. 
#		$roe,    # radius of window edge for trepan
#		$wobf,   # width at base factor, > 1 for narrower at spoke rim 
#       $rot,    # rotation factor for inside of spokes relative to outside 1= 1 revolution 0 to 0.2 are good. 

$c->{wheel}->bossindent(0.25,-0.01,1); # diameter of indent, depth of indent, how many passes, feedrate

$g->ginit(); 
$c->{wheel}->cut($g,0.0,0.0,0.0); 
$g->gend(); 
