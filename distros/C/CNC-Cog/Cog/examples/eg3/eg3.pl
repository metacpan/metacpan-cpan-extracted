#!/usr/bin/perl

use CNC::Cog;
use CNC::Cog::Gdcode; 
use CNC::Cog::Gcode; 

my %opt; 
$opt{allowed}='p'; 
@ARGV=grep { s/^-([$opt{allowed}])//?(($opt{$1}=1)&&0):1 } @ARGV;
grep { m/^-/ } @ARGV and die "Illegal option in @ARGV"; 

my ($g);
if ($opt{p})
{
  $g=new Gdcode("test.png",1.25,400,400);   # this uses the GD module to generate a .png file
}
else
{
   my $feed=5.0;                          # feed rate for cut. 
   $g=new Gcode("test.ngc",$feed);         # and this produces gcode in the file test.ngc. 
}

$c=newcogpair Cog(1.6,9,16); # Creates a pair of meshing wheels, with teeth module 1.6 (mm) one with 9, one with 16 teeth. 
$c->{wheel}->cutset(0.0625,4,-0.0125); # cuttersize, passes, passdepth 

$c->{pinion}->{passes}=8;              # need more depth on pinion. 
$c->{pinion}->{fillet}=1; 

$s=new Stack(0.125,4,-0.025);          # $cuttersize,$passes,$passdepth,$facedepth
$boss=new Boss(0.125,8,-0.0125,0.13);
$boss->{name}='Jim';                   # used in comments in gcode

$c->{pinion}->{name}='pinion';         # used in comments 
$c->{wheel}->{name }='wheel';          # used in comments 

$s->add($boss,$c->{pinion},$c->{wheel});

                
$g->ginit(); 
$s->cut($g,0,0,0); 
$g->gend(); 