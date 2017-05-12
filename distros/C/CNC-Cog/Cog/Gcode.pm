# Written by Mark Winder, mark.winder4@btinternet.com  
use vars qw($VERSION); 
$VERSION=0.061; 

package Gcode;
use vars qw(@ISA);  
@ISA=qw(CNC::Cog::Gcode); 
# I define another package Gcode, this enables you to say new Gcode(...
# instead of new CNC::Cog::Gcode(...;  


package CNC::Cog::Gcode;
use vars qw(@ISA);  
@ISA=qw(Exporter);
use Carp;

my $f="%9f "; 
my $ff="%2.1f";

my $lineno=0; 
# effectively providesone level of buffereing for commands. Needed to make sure recursive calls do what you think they should. 
sub proc
{
	my ($g,$c)=@_; # params are gcode object, code

	my ($file)=$g->{file}; 
    
	printf($file "%s\n",$g->{pending}) if ($g->{pending});
	$g->{pending}=$c; 
	return $c; 
}
# object creator
sub new
{
	my ($class,$file,$feed,$toolnumber)=@_; 
    $class=ref($class) || $class; 
    my ($x)={};
	$x->{file}=$file; 
	open($file,">".$file) or croak("Unable to open file $file for write");
	$x->{pending}="%\nG40 G17";
    $x->{feed}=$feed; 
    $x->{cuttersize}=0;
    $x->{toolnumber}=1; 
    $x->{toolnumber}=$toolnumber if (defined $toolnumber); 
	return bless $x,$class; 
}
# initialisation code at the start of gcode
sub ginit
{

}
sub setcuttersize
{
  my ($g,$s)=@_;  # set cutter diameter default to inches. 
               # can add pt for point, mm for millimetres, cm for centimetres
               # can add i for inches (default) 
               # can add t for thous of an inch 
  $s=~s/i//; 
  $s=~s/pt// and $s/=72; 
  $s=~s/mm// and $s/=25.4; 
  $s=~s/cm// and $s/=2.54;
  $s=~s/t// and $s/=1000.0; 

  $s=~/[a-zA-Z]/ and die "Invalid unit specification $s"; 

  $g->{cuttersize}=$s; 
   
}
sub getcuttersize
{
  my ($g)=@_; 

  return $g->{cuttersize}; 
}


# produces a comment protected by gcodes comment convention
sub gcomment
{
   my $gc=shift;
   my ($c)=@_; 

   $c=~s/\n$//; 
   my @c=split("\n",$c);
   @c=grep { $_ ne ''} @c; 
   return "" if (@c==0); 
   while (@c>1)
   { 
     $c=shift @c; 
     proc($gc,"( $c )");
   }
   $c=shift @c; 
   return proc($gc,"( $c )"); 
}
# rapid move command.
sub grapid
{
	my $g="G0"; 
	my $c; 
	my $gc=shift;
	while (@_)
	{
 	   $c.=sprintf("%s $f",uc($_[0]),$_[1]) if ($_[0] =~/^[xyz]$/i);
# 	   $c.=sprintf("F $ff",$_[1]) if ($_[0] =~/^f$/i);
	   shift; shift; 
	}
	return proc($gc, "$g $c") if ($c); 
	return ""; 
}
# move command. perhaps this would be a good point to explain the calling convention here. 
# its a bit odd. In order to preserve the useful feature of gcode that you can provide what
# ever parameters you want to provide (and in whatever order) the convention is that 
# that you pass an x followed by the x value and so on. 
# can be intollerent of faulty calls
sub gmove
{
	my $g="G1"; 
	my $c; 
	my $gc=shift;
    my $hasfeed=0; 
	while (@_)
	{
 	   $c.=sprintf("%s $f",uc($_[0]),$_[1]) if ($_[0] =~/^[xyz]$/i);
 	   $c.=sprintf("F $ff",$hasfeed=$_[1]) if ($_[0] =~/^f$/i);
	   shift; shift; 
	}
    $gc->{feedsent}||=0; 
    $c.=sprintf("F $ff",$gc->{feed}) if (!$hasfeed and !$gc->{feedsent}); 
    $gc->{feedsent}=1; 
	return proc($gc, "$g $c") if ($c); 
	return ""; 
}
sub gdwell
{
	my $g="G4 "; 
	my $c=''; 
	my $gc=shift;
	while (@_)
	{
      if ($_[0] =~/^[p]$/i) # we adopting a slightly different aroach here to other functions
      {                     # if  provided, ignore it, otherwise assume arg is dwell in seconds
        shift;              # so can do gdwell('p',2) or gdwell(2) 
      }
      else
      {
 	   $c.=sprintf(" P$f",$_[0]);
	   shift;
      }
	}
	return proc($gc, "$g $c") if ($c); 
	return ""; 
}

# arc clockwise, x,y and r radius only implemented. 
sub garccw
{
	# clockwise arc
	my $g="G2 "; 
	my $c; 
    my $gc=shift;
	while (@_) 
	{
 	   $c.=sprintf("%s $f",uc($_[0]),$_[1]) if ($_[0] =~/^[xyzrij]$/i);
 	   $c.=sprintf("F $ff",$_[1]) if ($_[0] =~/f/i);
	   shift; shift; 
	}
	return proc($gc,"$g $c\n") if ($c); 
	return ""; 
}
# arc clockwise
sub garcccw
{
	# counter clockwise arc
	my $g="G3 "; 
	my $c; 

    my $gc=shift; 
	while (@_) 
	{
 	   $c.=sprintf("%s $f",uc($_[0]),$_[1]) if ($_[0] =~/^[xyzrij]$/i);
 	   $c.=sprintf("F $ff",$_[1]) if ($_[0] =~/f/i);
	   shift; shift; 
	}
	return proc($gc,"$g $c\n") if ($c); 
	return ""; 
}
# cutter compensation on driving on the righ 
# you can supply an additional function if you want the compensation to linearly 
# come into effect as a move is performed. 
sub gcompr
{
	# cutter compensation on, cutting to the right 


	my ($c)="G42 "; 
    my ($gc)=shift;
	
	while ($_[0] =~/^[d]$/i)
	{
 	   $c.=sprintf("%s %d",uc($_[0]),$_[1]) ;
	   shift; shift; 
	}
	
	while (@_>0 and $_[0]=~/^G/i)
	{
            $c.=" ".$_[0]; 
            shift; 
            $gc->{pending}=''; # we clear this if additional values are passed 
	}
   return proc($gc,$c); 
}
# cutter (radius) compensation, drive on the left. 
sub gcompl
{
	# cutter compensation on, cutting to the left

	my ($c)="G41 "; 
    my ($gc)=shift;
	while ($_[0] =~/^[d]$/i)
	{
 	   $c.=sprintf("%s %d",uc($_[0]),$_[1]) ;
	   shift; shift; 
	}
	while ($_[0]=~/G/i)
	{
		$c.=" ".$_[0]; 
		shift; 
		$gc->{pending}=''; # we clear this if additional values are passed 
	}
   return proc($gc,$c); 
}
# switch off compensation. 
sub gcomp0
{
	# cutter compensation off

	my ($c)="G40 "; 
        my ($gc)=shift; 
	while (@_>0 and $_[0]=~/G/i)
	{
		$c.=" ".$_[0]; 
		shift; 
		$gc->{pending}=''; # we clear this if additional values are passed 
	}
   return proc($gc,$c); 
}
# end of program. 
sub gend
{
	my ($gc)=@_; 
	$gc->proc('');
	my $file= $gc->{file};
	print $file  "%\n"; 
	close $file; 
}

# The following routines are used for debug purposes. In this package they should always do nothing. 
sub gmark {} # make a cross mark at a given point
sub gline {} # draw a line between 2 points. 
sub gruler{} # draw a ruler for sizing purposes.
sub rednext   # make the next line red, not used in g code output produces comment  **** red **** 
{
  my ($g)=@_; 
  $g->gcomment("**** red ****"); 
}
1;

