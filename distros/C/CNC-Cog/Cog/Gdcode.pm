# Written by Mark Winder, mark.winder4@btinternet.com 
# This package is used for storing scaling information when plotting using GD. It is not used when generating gcode. 
# Its simple and fairly versatile, but still results in inverted y axis which are not taken account 
use strict;
use vars qw($VERSION); 
$VERSION=0.061; 

package Scale;
my $pi=4.0 * atan2(1, 1);
my $debug=0; 
my $yinvert=-1; # 1 for not inverted, -1 for inverted to correct way up. 
                # This is a debug setting, should be at -1, for correct orientation of y axis: +ve is up. 
sub new
{
	my $s={};

	$s->{ox}=$s->{oy}=0; 
	$s->{s}=1.0; 
    $s->{cuttersize}=0; 
	return bless $s;
}

sub setorigin
{
	my ($s,$x,$y)=@_; 

    $s->{ox}=$x;
	$s->{oy}=$y;

}
sub setpixelorigin
{
	my ($s,$x,$y)=@_; 

    $s->{pox}=$x;
	$s->{poy}=$y;

}

sub setscale
{
	my ($s,$scale,$xsize,$ysize)=@_; 

	$s->{s}=$xsize/$scale; 
	$s->{xsize}=$xsize; 
	$s->{ysize}=$ysize; 
	$s->{pox}=abs($xsize/2); 
	$s->{poy}=abs($ysize/2);
}

sub scalexy
{
	my $s=shift(@_); 
	my (@xyus)=@_;  # unscaled xy pairs
	my @xys;        # scaled xy pairs
#	print "scalexy b4 is @xyus\n"; 
	while (@xyus)
	{
		my $x=$xyus[0]; 
		my $y=$xyus[1];
		push(@xys, (int(0.5+($x-$s->{ox})*$s->{s})+$s->{pox}),int(0.5+(($y-$s->{oy})*$s->{s}*$yinvert)+$s->{poy})); 
		shift(@xyus); shift(@xyus); 
	}
#    print "scalexy after is @xys\n"; 
	return (@xys); 
}
sub scaled # scale a distance only, no origin offset, use for things like diameters
{
	my $s=shift(@_); 
	return map { int(0.5+$_*$s->{s}) } @_;  
}

# graphical routine. Has same interface as gcode pretty much.
package Gdcode; 
use vars qw(@ISA); 
@ISA=qw(CNC::Cog::Gdcode);
# I define another package Gdcode, this enables you to say new Gcode(...
# instead of new CNC::Cog::Gdcode(...;  
 

package CNC::Cog::Gdcode;
use GD;
use vars qw(@ISA);  
@ISA=qw(Exporter); 
#@EXPORT=qw( x y z d f r ); 
my $f="%9f "; 
my $ff="%2.1f";
#sub x {'x'}
#sub y {'y'} 
#sub z {'z'} 
#sub f {'f'} 
#sub r {'r'} 
#sub d {'d'}
sub new
{
	my ($class,$file,$scale,$xsize,$ysize)=@_;
    $class=ref($class) || $class; 
	my $g={};
	
	my $i = new GD::Image(abs($xsize),abs($ysize));
	my $s=new Scale; 
	$s->setscale($scale,$xsize,$ysize);
	$s->setorigin(0,0); 
	$g->{i}=$i; 
	$g->{x}=0; 
	$g->{y}=0;
	$g->{z}=0; 
	$g->{s}=$s; 
	$g->{file}=$file; 


	# allocate some colors
	$g->{col}->{white} = $i->colorAllocate(255,255,255);
    $g->{col}->{black} = $i->colorAllocate(0,0,0);       
	$g->{col}->{blue}  = $i->colorAllocate(0,0,255);
	$g->{col}->{dred}   = $i->colorAllocate(128,0,0);      
	$g->{col}->{bred}   = $i->colorAllocate(255,0,0);      
    $g->{col}->{green} = $i->colorAllocate(0,255,0); 
   

    #$red = $i->colorAllocate(255,0,0);      
    #$blue = $i->colorAllocate(0,0,255);
	#$green=$i->colorAllocate(0,255,0); 
	#$turk=$i->colorAllocate(0,255,255); 
	#$beig=$i->colorAllocate(196,128,0);
	#$purp=$i->colorAllocate(128,0,128);

    $g->{feed}=0; # compatability. 

	return bless $g,$class; 
}

# internal function. used for all circular arcs, emulates the 
# gcode arc command. 
sub range
{
  my ($v,$i,$x)=@_; 
  my ($r)=$x-$i; 

  while ($v>=$x) { $v-=$r; } 
  while ($v<$i)  { $v+=$r; } 
  return $v; 
}
sub arcpath
{
	my ($i,$s,$x1,$y1,$x2,$y2,$r,$col)=@_; 

    # ($yinvert<0) and ($x1,$y1,$x2,$y2)=($x2,$y2,$x1,$y1); 

	my $l=sqrt((($x2-$x1)**2)+(($y2-$y1)**2));            # dist between supplied points
#     printf "%f %f\n",$r,$l/2;
	my $l2=sqrt(abs($r**2-($l/2)**2)); 					      # dist from center of normal to arc center 
	my $a=2*atan2($l/2,$l2);                		      # vertex angle
	my $ra=0.5*($pi-$a);                                     # radial line line 1/2 angle
	my $cata=atan2($y2-$y1,$x2-$x1); 

 	my $a2=-($pi-$cata-$ra); 
	my ($cx,$cy)=($x1-$r*cos($a2),$y1-$r*sin($a2)); 
	
	# $i->arc($s->scalexy($cx,$cy),$s->scaled($r*2,$r*2),($a2)*180/$pi+360,($a2+$a)*180/$pi+360,$col);

    $a=$a*$yinvert; 
    $a2*=$yinvert; 

    $a2+=0.003;  # rounding error ? Problem in GD. 
    $a=$a2+$a;
    $a2=range($a2,0,2*$pi); 
    $a=range($a,0,2*$pi); 

#    if ($a>$a2)
    if ($yinvert<0)
    { 
      ($a,$a2)=($a2,$a); 
    }

    $i->arc($s->scalexy($cx,$cy),$s->scaled($r*2,$r*2),($a2)*180/$pi,($a)*180/$pi,$col);
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

  $g->{cuttersize}=$s;    # Thickness in inches
   
  ($s)=$g->{s}->scaled($s);
  $s=1 if ($s<1); 
  $g->{i}->setThickness($s);  
  
   
}

sub getcuttersize
{
  my ($g)=@_; 

  return $g->{cuttersize}; 
}

sub ginit
{
	my ($g)=@_; 
	
}
sub gcomment
{
   shift if (!ref($_[0]) eq '');    
   my ($c)=@_; 

   $c=~s/\n$//; 
   print  "*** $c \n" if ($c); 
   return; 
}
sub gmove
{
	my ($g)=shift; 
	my (@xy)=($g->{x},$g->{y}); 
	while (@_)
	{
	   $g->{$_[0]}=$_[1]  if ($_[0] =~/^[xyz]$/i);
	   shift; shift; 
	}
	push(@xy,$g->{x},$g->{y});
	
	my $col=$g->{z}>=0?$g->{col}->{green}:$g->{col}->{blue}; 
    $col=zcol($g);
	$g->{i}->line($g->{s}->scalexy(@xy),$col);
}
sub gdebug
{
  shift(); 
  ($debug)=@_; 
}
# debug only. 
sub gline
{
  # used for debug draws a line between 2 points

  my ($g)=shift; 

  return if (!$debug); 

  my ($x1,$y1,$x2,$y2)=@_; 

  $g->gmove('z',0.1);
  $g->gmove('x',$x1,'y',$y1);
 $g->gmove('z',-0.5); 
  $g->gmove('x',$x2,'y',$y2);
  $g->gmove('z',0.1);

}
# debug only. draws a cross. 
sub gmark
{ 
  my ($g,$x,$y)=@_; 

  my $d=0.025; 

#  return if (!$debug); 

  $g->gmove('z',0.1); 
  $g->gmove('x',$x,'y',$y);
  $g->gmove('x',$x-$d,'y',$y-$d); 
  $g->gmove('z',-0.15);
  $g->gmove('x',$x+$d,'y',$y+$d); 
  $g->gmove('x',$x,'y',$y); 
  $g->gmove('x',$x-$d,'y',$y+$d); 
  $g->gmove('x',$x+$d,'y',$y-$d);
  $g->gmove('x',$x,'y',$y); 
}
sub grapid
{
	my ($g)=shift; 
	my (@xy)=($g->{x},$g->{y}); 
    my ($z)=$g->{z};
    my ($col); 
 
	while (@_)
	{
	   $g->{$_[0]}=$_[1]  if ($_[0] =~/^[xyz]$/i);
	   shift; shift; 
	}
	push(@xy,$g->{x},$g->{y});
	
    $col=$g->{col}->{green};
    $col=$g->{col}->{bred} if ((defined $z and  $z<0) or (defined $g->{z} and $g->{z}<0)); 
    $g->{i}->setThickness(1);
	$g->{i}->line($g->{s}->scalexy(@xy),$col);

    if ($g->{cuttersize})
    {
     my ($s)=$g->{s}->scaled($g->{cuttersize});
     $s=1 if ($s<1); 
     $g->{i}->setThickness($s);  
    }
}
sub rednext
{
  my ($g)=@_; 
  $g->{rednext}=1; 
  print "**** red ****\n"; 
} 
sub zcol
{
  my ($g)=@_; 
  my $z=$g->{z}; 
  my $col; 

  if ($g->{rednext}==1)
  { 
     $g->{rednext}=0; 
     $col = $g->{col}->{bred};
     return $col; 
   }
  
   
    if ($z>0)
    {
      $col=$g->{col}->{green};
     }
    else
    {
      $z=abs($z); 

      my ($r,$gr,$b); 
  
      my $l=127*$z/0.3; 
      my $ll=127*($z/0.1-0.5);
       $r=$l+$ll;
       $b=$l-$ll;
       $gr=$l; 

      
      $r=0 if ($r<0);
      $gr=0 if ($gr<0);
      $b=0 if ($b<0);
      $r=255 if ($r>255);
      $gr=255 if ($gr>255);
      $b=255 if ($b>255);
      
      $col = $g->{i}->colorAllocate($r,$gr,$b); 
    }
  return $col; 
}
sub zcol2
{
  my ($g)=@_; 
  my $z=$g->{z}; 
  my $col; 
   
    if ($z>0)
    {
      $col=$g->{col}->{green};
     }
    else
    {
      $z=abs($z); 

      my ($r,$gr,$b); 
      my $maxz=0.3; 
 
      my $lum=$z/$maxz;
      
      my $col=2*3.14159*$z/$maxz;

      $r=127+127*cos($col); 
      $gr=127+127*cos($col+3.14159*2/3); 
      $b=127+127*cos($col+3.14159*4/3); 
      
      print "r=$r g=$gr b=$b\n"; 
      $r=0 if ($r<0);
      $gr=0 if ($gr<0);
      $b=0 if ($b<0);
      $r=255 if ($r>255);
      $gr=255 if ($gr>255);
      $b=255 if ($b>255);
      
      ($r,$gr,$b)=map { $_=$_/4 } ($r,$gr,$b); 

# print "r=$r g=$gr b=$b\n";  
      $col = $g->{i}->colorAllocate(int($r),int($gr),int($b)); 
    }
  return $col; 
}
sub garcccw
{
	my ($g)=shift; 
	my (@xy)=($g->{x},$g->{y}); 
	my ($r); 
	while (@_)
	{
	   $g->{$_[0]}=$_[1]  if ($_[0] =~/^[xyz]$/i); # i,j not implemented
   	   $r=$_[1]  if ($_[0] =~/^[r]$/i);
	   shift; shift; 
	}

    
	@xy=(@xy,$g->{x},$g->{y}); 
    my $col;

    $col=zcol($g);
     

	arcpath($g->{i},$g->{s},@xy,$r,$col); 
}
sub garccw
{
	my ($g)=shift; 
	my (@xy)=($g->{x},$g->{y}); 
	my ($r); 
	while (@_)
	{
	   $g->{$_[0]}=$_[1]  if ($_[0] =~/^[xyz]$/i); # i,j not implemented
   	   $r=$_[1]  if ($_[0] =~/^[r]$/i);
	   shift; shift; 
	}
	@xy=($g->{x},$g->{y},@xy); 
	my $col;
    $col=zcol($g);
	arcpath($g->{i},$g->{s},@xy,$r,$col); 
}
# although cutter compensation changes the path plotted by, roughly speaking
# the radius of the tool, we dont show this here, all we show 
# is the actual path plotted. These functions therefore do nothing 
sub gcompr
{
	
}
sub gcompl
{
	
}
sub gcomp0
{
	
}
# generate the output 
sub gend
{
	my ($g)=@_; 
	open(F,">".$g->{file}) or die "Cannot open file ".$g->{file}; 
	binmode F; 
    print F $g->{i}->png; 
    close F; 
}
sub gruler
{ 
  my ($g,$x,$y,$ndiv,$div)=@_; 
  my $col=$g->{col}->{blue}; 
  my $n=0; 
  my $ys=0.01;    
  my $yl=$ys*3; 
  $g->{i}->line($g->{s}->scalexy($x,$y,$x,$y-$yl),$col); 
  $ndiv*=10; 
  $div/=10; 
    while ($n++<$ndiv)
    {
    	$g->{i}->line($g->{s}->scalexy($x+$n*$div-$div,$y,$x+$n*$div,$y),$col);    
        
        my ($dy)=$ys; 
        $dy=$yl if ($n%10==0); 
        $g->{i}->line($g->{s}->scalexy($x+$n*$div,$y,$x+$n*$div,$y-$dy),$col);    
    }
}
# dwell, do nothing!
sub gdwell
{
}

1;
