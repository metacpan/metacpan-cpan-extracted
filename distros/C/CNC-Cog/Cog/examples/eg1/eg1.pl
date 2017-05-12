#!/usr/bin/perl
    
                                  # This contains the cog cutting functions. 
use CNC::Cog;                          # This contains the jpeg output functions
use CNC::Cog::Gdcode;                       # and this the gcode output functions
use CNC::Cog::Gcode;                        # Actually you only need one of these. 

$c=newcogpair Cog(3.0,7,18);      # make a pinion and a wheel module 3, 
                                  # with 7 and 18 teeth.
                                  # you can use CNC::Cog or Cog here. 

$c->cutset({cuttersize=>0.125,passes=>3,passdepth=> -0.025 }); 

$c->{wheel}->hole(0.125); 
$c->{pinion}->hole(0.25); 

my $feed=3; 
#my $g=new gcode("test.ngc",$feed,5);        # for gcode out use this line
                  # output file, feed rate, tool number for offset commands 
my $g=new Gdcode("test.png",4.50 ,1300,1300);# for jpg use this line 
                  # file, size in inches horizontally, x and y size in pixels
                  # You can use CNC::Cog::Gdcode or Gdcode here
$g->ginit();                               

$c->{wheel}->cut($g,0,-0.75,0); # x,y,z. 
$c->{pinion}->cut($g,0,1.25,0);

$g->gend();                 # finalise graphics operations, write files etc. 