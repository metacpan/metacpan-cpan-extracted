# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { 
         use_ok('CNC::Cog'); 
	 use_ok('CNC::Cog::Gcode'); 
      };

#########################

use strict; 

my $c=newcogpair Cog(3.0,7,18);
$c->cutset({cuttersize=>0.125,passes=>3,passdepth=> -0.025 });
my $feed=42; 
my $g=new Gcode("t/test1_generated.ngc",$feed,5);
$g->ginit();                               
$c->{wheel}->cut($g,0,-0.75,0); # x,y,z. 
$g->gend(); 

my $hash1=hashfile("t/test1_generated.ngc"); 
my $hash2=hashfile("t/test1_provided.ngc"); 


ok($hash1==$hash2,"Wheel generation test, produced code agrees with provided sample"); 

$g=new Gcode("t/test4_generated.ngc",$feed,5);
$g->ginit();                               
$g->gcomment("This is the output from test 4"); 
$g->gend(); 
$hash1=hashfile("t/test4_generated.ngc"); 
$hash2=hashfile("t/test4_provided.ngc"); 

ok($hash1==$hash2,"Simple G-code comment test, produced code agrees with provided sample"); 


# rudimentary hashing function, token based, 
# ignores white space, and reformats all numbers.
sub hashfile
{
  my ($file)=@_; 
  my @tokens; 

  open(F,$file) or die("cannot open file $file"); 

  while (<F>)
  {

    my @line=split(/\s+/); 

   # @line=map{ $_!=0?sprintf("%2.2f",$_):$_} @line; 
    @line=map{ m/^[-+0-9.]+$/?sprintf("%2.2f",$_):$_} @line; 
    push(@tokens,@line); 
  } 
  close F; 
  
  my $sum=0; 
  my $count=0; 
  for my $x (split(//,join(' ',@tokens)))
  { 
     $count++;
     $sum=$sum^((ord($x)+$count)<<($count%16)); 
  }
  return $sum; 
} 
