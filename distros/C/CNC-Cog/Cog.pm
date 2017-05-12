#Written by Mark Winder, mark.winder4@btinternet.com 
# Copyright 2004,2005
use GD;
use strict;

package Profile;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.061;

my $pi=4.0 * atan2(1, 1);
# profile 
sub new
{
  my ($class)=shift(@_);
  my ($p)={}; 

  if (ref($_[0]) eq $class)
  {
     $p=$_[0]; 
     return $p->copy; 
  } 



  $p->{points}=[]; 
  $p->{comments}=[]; 
  
  while (@_)
  { 
    push(@{$p->{points}},[shift(@_),shift(@_)]); 
  }
  $#{$p->{comments}}=$#{$p->{points}};  
  return bless $p , $class; 
} 
#profile
sub comment
{
  my($p,@c)=@_; 
  my $n=@{$p->{points}}; 
  $p->{comments}->[$n].=join("\n",@c);  # This creates a new comment entry, now @comments=@points+1; 
}
# profile 
sub copy
{
   my ($p)=@_;
   my $q={}; 

   $q->{points}=[]; 
   $q->{comments}=[]; 

   for (@{$p->{points}})
   { 
     push(@{$q->{points}},[@$_]);
   }
   @{$q->{comments}}=@{$p->{comments}}; 
  
   return bless $q, ref($p); 
}
   
# profile 
# return all points, 1 point or a range of points as a 1 dimentional array (alternate x-y pairs. ) 
#  eg allowed a,b are -3,-1  for last 3 points, oldest first. 
#  -1 for last point 
#  0 for 1st point 
#  nothing for all points

sub points
{ 
  my ($p,$a,$b)=@_;
  
  if (!defined $a and !defined $b) 
  { 
    return map { ($$_[0],$$_[1]) } @{$p->{points}}; 
  }
  elsif (!defined $b)
  {
    return map { ($$_[0],$$_[1]) } ${$p->{points}}[$a];     
  }
  else
  {
    my @pp=@{$p->{points}};
    @pp=@pp[$a,$b]; 
    return map { ($$_[0],$$_[1]) } @pp;     
  }
} 

# profile 
# Take 2 (for a move) or 4 (for an arc) points and add to end of the profile 
# can also take an existing profile, adding it to the 1st. 
sub ppush
{
  my ($p)=shift(@_); 
  if (ref($_[0]) ne '')
  { 
    my $q=shift(@_);
    my $sp=@{$p->{points}}; 

    $#{$q->{comments}}=$#{$q->{points}};

    my @comments=@{$q->{comments}}; 
    if ($#{$p->{comments}}>$#{$p->{points}}) # if we called comment in advance, we need to add the last comment on to 1st comment of new one. 
    { 
      $p->{comments}->[-1]=$p->{comments}->[-1].$q->{comments}->[0]; 
      shift (@comments); 
    }
    push(@{$p->{comments}},@comments); 
    push(@{$p->{points}},@{$q->{points}}); 
  } 
  else
  { 
   push(@{$p->{points}},[@_]); 
  }
  $#{$p->{comments}}=$#{$p->{points}}; # if a comment has been added, this has no effect if 1 point added, otherwise it adds empty entries to the comments array. 
  return $p; 
}

#profile
sub shift
{
  my ($p)=shift(@_); 
  
  shift(@{$p->{comments}}); # Throw away this comment. 
  my $pp=shift @{$p->{points}}; 
  return @$pp; 
}

# profile 
# insert a point backwards into the profile. n=1 means between last point and point before. 
sub insertback
{ 
   my ($p,$n,$x,$y,$r,$ccw)=@_;  # set n to zero makes same as push, n=1 means 1 before latest point. 
   $#{$p->{comments}}=$#{$p->{points}};
   splice(@{$p->{points}},@{$p->{points}}-$n,0,[$x,$y,$r,$ccw]); 
   splice(@{$p->{comments}},@{$p->{comments}}-$n,0,""); 

   return $p; 
}

# profile 
# This function deduplicates repeated points. These can arrise for example if you mirror or rotate a profile and then add them 
# together. Because rounding errors can and do arrise, we need to have a fudge factor here that is the small amount
# used in comparison. Anything smaller than this is considered the same. I may have set this a little small, 
# but it worked for me. Change $d if you need to. 
#
# The reson duplicates are bad is that it confuses reference to particular points, eg 5 points before the 
# present one when doing things like smoothing. 
sub dedupe
{
  my ($p)=@_; 

  my $d=1e-10;  # How small before point is considered a duplicate ? 

  my @points; 
  my @comments; 

  my $old; 
  
  my $i=0;   
  for (@{$p->{points}})
  {
     
     if (abs($$_[0]-$$old[0])>$d or abs($$_[1]-$$old[1])>$d or !$old)
     {
       push(@points,$_); 
       push(@comments,$p->{comments}->[$i]);
     }
     else
     {  # point is a duplicate, not including. 
       $comments[-1].=$p->{comments}->[$i]; 
     }
     $i++; 
     $old=$_;
  }
#  @{$p->{points}}=@points; 
  $p->{points}=\@points; 
  $p->{comments}=\@comments; 
  return $p; 
} 

# profile. 
# reverse the cut direction of a profile. This also cleverly attempts to move both arc paramters and comments
# around to take account of the new cut order, so that the comments still get printed out in the 
# right place. Bit academic really as if you are reversing round a bend comments about whats round the corner
# are probably misguided any way!
sub reverse
{
  my ($pp)=@_; 

  $#{$pp->{comments}}=$#{$pp->{points}};  
  my $p=$pp->copy; 

  @{$p->{points}}=reverse @{$p->{points}}; 
  @{$p->{comments}}=reverse @{$p->{comments}}; 

  my @arc1=(); 
  my @arc2=(); 
  for (@{$p->{points}})
  { 
     @arc2=($$_[2],$$_[3]==0); 
     @$_[2,3]=@arc1; 
     @arc1=@arc2;
  }  
 
  
  return $p; 
}
#profile
# replace the latest point or some point before it. 
sub replaceback
{ 
   my ($p,$n,$x,$y,$r,$ccw)=@_;  # set n to zero to replace the latest point  
   splice(@{$p->{points}},@{$p->{points}}-$n-1,1,[$x,$y,$r,$ccw]); 
   return $p; 
}
#profile
sub print # formatted debug 
{ 
  my ($p)=@_; 
  $"=","; 
  my $i=0; 
  for (@{$p->{points}})
  { 
        my $c=$p->{comments}->[$i]; 
        $c.="\n" if ($c and $c!~ m/\n$/s ); 
        print "**** $c" if ($c); 
        print "[ @$_ ]\n"; 
        $i++; 
     
  }
  my $c=$p->{comments}->[$i]; 
  $c.="\n" if ($c and $c!~ m/\n$/s ); 
  print "**** $c" if ($c); 

  return $p; 
} 


# just so as I remember matric rotations are as follows: 
# cw rotation,   cos a  sin a
#                -sin a cos a
#
# ccw rotation   cos a  -sin a
#                sin a  cos a



# Gives ccw rotation about the supplied point by an angle $a in radians
# if xc,$yc ommitted, rotation about origin. 
# profile 
sub rotate
{ 
  my ($pp,$a,$xc,$yc)=@_; 

  my $p=$pp->copy; 

  for (@{$p->{points}})
  { 
     @$_=($$_[0]-$xc,$$_[1]-$yc,$$_[2],$$_[3]);
     
  }

  for (@{$p->{points}})
  { 
     @$_=($$_[0]*cos($a)-$$_[1]*sin($a),$$_[0]*sin($a)+$$_[1]*cos($a),$$_[2],$$_[3]);
   
  }

   
  for (@{$p->{points}})
  { 
     @$_=($$_[0]+$xc,$$_[1]+$yc,$$_[2],$$_[3]); 
  }
  return $p; 
} 

# mirror about the y axis
# profile 
sub mirrory
{ 
  my ($pp)=@_; 

  my $p=$pp->copy; 

  for (@{$p->{points}})
  { 
     @$_=(-$$_[0],$$_[1],$$_[2],$$_[3]==0);
     
  }

  return $p; 
} 

# A translation, all points moved by this vector. 
# profile 
sub move
{ 
  my ($pp,$xc,$yc)=@_; 

  my $p=$pp->copy; 

  for (@{$p->{points}})
  { 
     @$_=($$_[0]+$xc,$$_[1]+$yc,$$_[2],$$_[3]);
     
  }
  return $p; 
} 

# similar to smooth, which joints a line to an arc with another arc, this function
# takes two lines that join at an angle and generates an arc that joins them of radius r, 
# chopping out a section of each line where the arc goes. Idea is to make a smooth transition
# so that on concave cuts it is possible to cut with a circular cutter of more than 
# infinitely small diameter! and on conves cuts it just looks nicer, or can do. 
# This could be incorporated into smooth so that smooth works even when lines rather 
# than arcs are given, but havnt done that. 
# profile 
sub linesmooth
{
  my ($p,$r,$n)=@_; 


  # assume 3 points l1,l2,l3, where l2 is the nth point in the profile, 0 means penultimate point though. 
  # want to insert circular section such that circle radius r is tangential. 

  # simple trig gives distance of the join points along each line as 
  # l=r/tan k where k is half the angle l1 l2 l3. 
  # calulate this as 0.5 * ( 180 -a1 -a3 ) where tan a1 = (x2-x1)/(y2-y1), tan a3=(x3-x2)/(y3-y2) 
  # from l we calculate the 2 new points parametrically sliding from l2 to l1, and l2 to l3. 

  my (@points)=@{$p->{points}}; 
  

  $n=$#points if ($n==0); 

  my (@p1)=@{$points[$n-1]}; 
  my (@p2)=@{$points[$n]}; 
  my (@p3)=@{$points[$n+1]}; 

  my (@extra)=(abs($r)); 
  
  my $k=0.5*($pi-atan2(abs($p2[1]-$p1[1]),abs($p2[0]-$p1[0]))-atan2(abs($p3[1]-$p2[1]),abs($p3[0]-$p2[0])));
  
  $extra[1]=($r>0);
  $r=abs($r); 
   

  my $l=$r*cos($k)/sin($k); 

  
  # Find the start of arc by parametric substitution into p2,p1 
  my $ll=sqrt(($p2[0]-$p1[0])**2+($p2[1]-$p1[1])**2); # length of this line;

  my $sax=$p2[0]*($ll-$l)/$ll+$p1[0]*($l/$ll); 
  my $say=$p2[1]*($ll-$l)/$ll+$p1[1]*($l/$ll); 

  # Find the end of arc by parametric substitution into line p2,p3 
     $ll=sqrt(($p3[0]-$p2[0])**2+($p3[1]-$p2[1])**2); # length of this line; 
  my $eax=$p2[0]*($ll-$l)/$ll+$p3[0]*($l/$ll); 
  my $eay=$p2[1]*($ll-$l)/$ll+$p3[1]*($l/$ll); 

  $p->replaceback(@points-$n-1,$sax,$say); 
  $p->insertback(@points-$n-1,$eax,$eay,@extra); 
  return $p; 
}
# see wheel smooth.
# profile 
# p the profile, smooth3e the last 3 points, which should be line then arc. Smooth with circle radius r. 
# x, y is the center of the arc. joining last 2 points in profile 
# profile 
sub smooth
{ 
  my ($p,$r,$x,$y)=@_;
  $"=',';  
my $c; 

  my $w=Wheel->new(); # actually, we know that no characteristics from wheel are used here, so use a new one. 
  # assume you call with last point is an arc, 

  $p=$p->move(-$x,-$y);
  
  my @ps=@{$p->{points}}; 

  my @last=grep { defined } @{$ps[-1]}; 
  my @l2  =grep { defined } @{$ps[-2]};
  my @l1  =grep { defined } @{$ps[-3]};

  my $last="last"; 
  my $l2='l2'; 
  my $swap=0; 
  
  my @extra;  

  if (@last==2) # need to swap order. 
  { 
     my @tmp=@l1; @l1=@last; @last=@tmp; 
     @last[2,3]=@l2[2,3];
     @extra=@l2[2,3];
     @l2[2,3]=();
     @l2=grep{ defined} @l2;
     @last=grep { defined } @last;   
     $l2='last'; 
     $last='l2';
     $swap=1; 
  }

  die "$last point needs to be arc is @last" if (@last==2);
  die "$l2 must be line , is @l2" if (@l2 != 2); 

  @l1=@l1[0,1]; # not intrested in arc or line. 

  my $a1=180*atan2($last[1]-$l2[1],$last[0]-$l2[0])/$pi; 
  my $a2=180*atan2($l2[1]-$l1[1],$l2[0]-$l1[0])/$pi; 

  $c=0; 
  $c=1 if (($a1-$a2+360+180)%360-180<0);                   # This works round bugs. reverses circle. 

  my (undef,undef,$sax,$say,$eax,$eay)= $w->smooth(@l1,@l2,$last[2],-$r*(1-$c-$c) );
 
  if ($swap)
  {
    my @tmp=@l1; @l1=@last; @last=@tmp; 
    @last[2,3]=(); 
    ($sax,$say,$eax,$eay)=($eax,$eay,$sax,$say); 
  }

  $p->replaceback(1,$sax,$say,@extra); 
  $p->insertback(1,$eax,$eay,$r,($swap==0)!=$c); 
  $p=$p->move($x,$y);
  return $p;        
}

# profile
#  
# move 1 point from start to finish. Used when we want to start cutting a profile in better place. 
# move any comments also. 
sub movestartfin
{
    my ($p)=@_; 

    $#{$p->{comments}}=$#{$p->{points}};  
    my @points=@{$p->{points}}; 
    my @comments=@{$p->{comments}}; 

   
    @points=(@points[1..$#points,0]);
    @comments=(@comments[1..$#points,0]);
    
#     @{$p->{points}}=@points; 
    $p->{points}=\@points; 
    $p->{comments}=\@comments;

    return $p; 
 
}

# profile
#  
# move 1 point from finish to start. Used when we want to start cutting a profile in better place. 
# move any comments also. 
sub movefinstart
{
     my ($p)=@_; 

    $#{$p->{comments}}=$#{$p->{points}};  
    my @points=@{$p->{points}}; 
    my @comments=@{$p->{comments}}; 

   
    @points=(@points[-1..$#points-1]);
    @comments=(@comments[-1..$#points-1]);
    
    $p->{points}=\@points; 
    $p->{comments}=\@comments;

    return $p; 
 
}

# profile 
sub plot
{ 

  my ($p,$g,$z,$passes,$passdepth,$open)=@_; 

  my @points=@{$p->{points}};
  my @point1=@{$points[0]};
  my @point2=@{$points[1]};
  my $point; 

  my $zup=0.05;
  my $zdown=$z; 

  $z=$zup; 

  $g->gmove('z',$z); 
  $g->gmove('x',$point1[0],'y',$point1[1]); 

  my $i=0; 

  for my $pass ( 1..$passes) 
  { 
#      $z+=$passdepth; 
     $i=0; 
     for $point (@points,\@point1)
     { 
       
       if ($point==\@point1 and $open ) # last point, return to start. Open if set, allows a non-closed profile to be cut. Debug ? 
       {
          $z=0.1; 
          $g->gmove('z',$z); 
       }

       $g->gcomment("Pass $pass of $passes ".$p->{comments}->[$i]) if ($p->{comments}->[$i]); 

       if ($$point[2] and $$point[3] and $i!=0) # radius of curveture, ccw , not cw  for arc. 
       { 
         $g->garcccw('z',$z,'x',$$point[0],'y',$$point[1],'r',$$point[2]); 
       }
       elsif ($$point[2] and $i!=0 ) # for cw arc 
       { 
         $g->garccw('z',$z,'x',$$point[0],'y',$$point[1],'r',$$point[2]); 
       } 
       else  # for move. First point is always a move, since we're there already in fact.  
       { 
        $g->gmove('z',$z,'x',$$point[0],'y',$$point[1]); 
       } 
       
       $z=$zdown+$passdepth*$pass; 
       $i++; 

     }
  }
  # finally we repeat point 2 becasue z was being phased in during the this point and we want full depth. 
       $point=\@point2; $i=1; 
       $g->gcomment("Pass final ".$p->{comments}->[$i]) if ($p->{comments}->[$i]); 

       if ($$point[2] and $$point[3] and $i!=0) # radius of curveture, ccw , not cw  for arc. 
       { 
         $g->garcccw('z',$z,'x',$$point[0],'y',$$point[1],'r',$$point[2]); 
       }
       elsif ($$point[2] and $i!=0 ) # for cw arc 
       { 
         $g->garccw('z',$z,'x',$$point[0],'y',$$point[1],'r',$$point[2]); 
       } 
       else  # for move. First point is always a move, since we're there already in fact.  
       { 
        $g->gmove('z',$z,'x',$$point[0],'y',$$point[1]); 
       } 

  
  $g->gmove('z',0.05);
}  
#############################################
# end of package profile 
#############################################

# This holds the information for a a single wheel: a pinion or spur gear.  
package Wheel;

use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.061; 

my $mm;
$mm=$mm=1.0/25.4;;    # 1mm is this inches; 

sub hole
{
  my ($w,$s,$x,$y)=@_; 

  if (!defined $x and !defined $y) # assume center
  { 
     $w->{holesize}=$s; 
  }
  else
  { 
    die "x/y parameters to hole function not yet implemented. "; 
    my $h=Hole->new($w->{cuttersize},$w->{passes},$w->{passdepth},$s/2); 
    my @holes; 
    $w->{holes}=\@holes if (!$w->{holes}); 
    push(@{$w->{holes}},$h); 
  } 
}
# wheel
sub passes
{
  my ($w)=@_; 

  return $w->{passes}; 
}
# wheel
# set the module and number of teeth. 
sub new
{
    my ($s,$m,$n)=@_; 
    $s={};
    $s->{n}=$n; 
    $s->{m}=$m; 

    return bless $s;
}
# Trepan: - to cut a hole in. If you want holes in your wheels, call this functions. ( Ie you want spokes!) 
# Known bugs: (1) As you increase the number of spokes, roe, spoke width or width at base factor or decreasethe boss radius there comes a time when there is 
# "not enough room round the boss for the spokes. This is not handles well, instead of doing a little arc which is the circumference of the booss
# what happens is you get most of a circle in the other direction. Catastrophic of course. 
sub trepan
{
  my ($w,        # pointer to self, a wheel. 
        $spoken, # number of spokes
        $wos,    # total width of spokes in inches
        $bsf,    # boss radius as a factor of pitch radius (dimentionless)  : Now absolute in inches. 
        $rsf,    # rim size in inches. 
        $roe,     # radius of window edge   (in inches, the curved radius of the join between a spoke and the rim or boss
                 # not that this must be more than the cutter size or you cant cut it! This is radius, not diameter. 
        $wobf,    # width at base factor, > 1 for wider spoke base. Tapered spokes anyone ? 
        $srf     # spoke rotation factor rotates spoke position this proportion of a full rotation
                  # on outer rim 
                 # values 0 to 0.1 give good results. 
        )=@_; 

# ($spoken,$wos,$bsf,$rsf,$roe,$wobf)=(6,0.5,0.25,0.35,0.075,1.0); 

# for now we just store the values in the wheel. 
        $w->{spoken}=$spoken; 
        $w->{wos}=$w->dim($wos);  
        $w->{bsf}=$w->dim($bsf);   
        $w->{rsf}=$w->dim($rsf);   
        $w->{roe}=$w->dim($roe);   
        $w->{wobf}=$wobf;    
        $w->{srf}=$srf; 
}

sub bossindent
{
  my ($c,$sized,$passdepth,$passes,$feed)=@_; 
  # arguments are cog, diameter of indent, depth for each pass  and number of passes, optional $feedrate
  # note that these are different to the main cutting ones because it doesnt go all the way through material for a start. 

  $c->{bi_passdepth}=$c->dim($passdepth); 
  $c->{bi_passes}=$passes; 
  $c->{bi_feed}=$feed;
  $c->{bi_sized}=$c->dim($sized); # diameter

}

# private function # 
sub cutbossindent
{
  my ($c,$g,$x,$y)=@_; 
  return if (!$c->{bi_sized}); 
    
  $c->{bi_feed}||=$g->{feed}; 
  $g->grapid('z',0.1);
  $g->grapid('x',$x,'y',$y); 

  my $sized=$c->{bi_sized}-$c->{cuttersize};

  my $pass=0; 
  my ($step)=$c->{cuttersize}/2; 
  $step==0 and die "Need a cuttersize set.";
  
  my $z=0; 
  while ($pass++<$c->{bi_passes})
  {
    #print "pass=$pass cpasses =".$c->{bi_passes}."\n";
    
    $z+=$c->{bi_passdepth};
    $g->gcomment("Cutting indent pass $pass of ".$c->{bi_passes}); 
    $g->gmove('x',$x,'y',$y,'z',$z,'f',$c->{bi_feed});
    my $r=0;        
    while ($r+$step<0.5*$sized)
    {      
      $r+=$step; 
      $g->gcomment("r is $r"); 
      $g->gmove('x',$x+$r,'y',$y);
      $g->garccw('x',$x-$r,'y',$y,'r',$r); 
      $g->garccw('x',$x+$r,'y',$y,'r',$r); 
    }
   
    $step=0.5*$sized-$r; 
    if ($step>0)
    {      
      $r+=$step; 
      $g->gcomment("final   r is $r"); 
      $g->gmove('x',$x+$r,'y',$y);
      $g->garccw('x',$x-$r,'y',$y,'r',$r); 
      $g->garccw('x',$x+$r,'y',$y,'r',$r); 
    }
  }
   
  $g->grapid('z',0.1);   
}  

# actually cut the requested trepanning scheme
# note that the nasty smooth algorithmn only works if the circle is centered on origin 0,0. 
# for the moment, easy way to correct this is to do all calculations assuming origin based wheel 
# then offset just before plotting with xi yi, the initial position, which is the real wheel center.
# private function # 
sub cuttrepan
{
    my ($cp,
        $gp, $xi,$yi,$zi) =@_;  

    my ($spoken, # number of spokes
        $wos,    # total width of spokes
#        $bsf,    # boss radius as a factor of pitch radius
        $bossradius, # now absolute in inches
        $rsf,    # rim size factor as proportion of pitch radius. # Now absolute in inches, size of rim 
        $roe,     # radius of window edge
        $wobf,   # width at base factor, > 1 for wider spoke base
        $srf
        )= map { $cp->{$_} } qw(spoken wos bsf rsf roe wobf srf); 

    $cp->{mm} or $cp->{mm}=1.0/25.4;

    map{ eval '\$$_=$cp->{$_} ' } qw(spoken wos bsf rsf roe wobf); 
    $wobf ||= 1.0; # default to non-tapered spokes. 
 
    return if (!$spoken);   # no spokes, no trepanning. 

    my $mm=$cp->{mm}; 
    my $pi=4.0 * atan2(1, 1);

    my $rr=$mm*(1-$rsf)*$cp->{dw}/2; # rim radius; 
 

    $wos=0.5*$wos/$spoken;
  #  $wosb=$wobf*$wos; # width at boss
    
    my $wosb=$wos;    # width of spoke base, near center of wheel.
    $wos=$wos/$wobf;  # width of spoke at the rim, less than base width if wid of base factor greater than 1. 
      
    $gp->grapid('z',0.1);
    $gp->grapid('x',$xi,'y',$yi);  
    $srf=$srf*2*$pi; 
    my (@xy,@l2);
    my ($tx,$ty); # temory x,y variables; 
    my ($x,$y); 
    my ($wsx,$wsy);

    for my $w  ( 0..$spoken-1)   # for each window, we calculate all the points, and put them on a stack. 
    {                         # before we plot, we process to radius the sharp edges. 
        my $t1=2*$pi*$w/$spoken; 
        my $t2=$t1+2*$pi/$spoken; # end of this window
        my $d; 
        my $first=1;                                             # This flag to control entry moves on 1st pass. 
        my $z=$zi; 
        $d=$wosb/$bossradius;

        my $passno=0; 
        while ($passno++ < $cp->{passes})
        {

        $x=$bossradius*cos($t1+$pi/$spoken);                      # positioning for 2nd half of circle segment at bossradius. 
        $y=$bossradius*sin($t1+$pi/$spoken); 
        push(@xy,$x,$y); 
        
        $x+=$bossradius*(cos($t2-$d)-cos($t1+$pi/$spoken));       # rotation at boss radius
        $y+=$bossradius*(sin($t2-$d)-sin($t1+$pi/$spoken));                                                    
        my $t=$t2-$d; 
        push(@xy,$x,$y); 
         
        $d=$wos/$rr; 
        $x+=$rr*cos($t2-$d+$srf)-$bossradius*cos($t);             # radial move to rim 
        $y+=$rr*sin($t2-$d+$srf)-$bossradius*sin($t);
        push(@xy,$x,$y); 
 
        $x+=$rr*(cos($t1+$d+$srf)-cos($t2-$d+$srf));              # rotatin around rim 
        $y+=$rr*(sin($t1+$d+$srf)-sin($t2-$d+$srf));
        $t=$t1+$d+$srf; 
        push(@xy,$x,$y); 
 
        $d=$wosb/$bossradius; 
        $x+=$bossradius*cos($t1+$d)-$rr*cos($t);                  # radial move back towards center 
        $y+=$bossradius*sin($t1+$d)-$rr*sin($t); 
        push(@xy,$x,$y);
                        
        $x=$bossradius*cos($t1+$pi/$spoken);                      # remaining half of rotation around boss. 
        $y=$bossradius*sin($t1+$pi/$spoken); 
        push(@xy,$x,$y); 

        if ($first)
        {
          $gp->gcompr('d',$gp->{toolnumber},$gp->gmove('x',$xi+shift(@xy),'y',$yi+shift(@xy))); 
        }
        else 
        {
          # $gp->gmove('x',$xi+shift(@xy),'y',$yi+shift(@xy),'z',$z)
           shift(@xy); shift(@xy); 
        }
        $gp->gcomment(sprintf "Trepanning - window %d pass %d of %d", $w+1,$passno,$cp->{passes});  
        $z+=$cp->{passdepth} ; # passdepth -ve 

        @l2=$cp->rsmooth(shift(@xy),shift(@xy),shift(@xy),shift(@xy),$bossradius,-$roe);
        @xy=(@l2,@xy); 
        $gp->garcccw('x',$xi+($tx=shift(@xy)),'y',$yi+($ty=shift(@xy)),'r',$bossradius,'z',$z); # rotation at boss radius, add in z incremen 


        @l2=$cp->smooth(shift(@xy),shift(@xy),shift(@xy),shift(@xy),$rr,$roe); 
        @xy=(@l2,@xy);                                                   
        $gp->garccw('x',$xi+shift(@xy),'y',$yi+shift(@xy),'r',$roe);         
       
        $gp->gmove('x',$xi+shift(@xy),'y',$yi+shift(@xy));               # line outwards
        $gp->garccw('x',$xi+shift(@xy),'y',$yi+shift(@xy),'r',$roe);            
       
        
        @l2=$cp->rsmooth(shift(@xy),shift(@xy),shift(@xy),shift(@xy),$rr,-$roe);
        @xy=(@l2,@xy); 
        $gp->garccw('x',$xi+shift(@xy),'y',$yi+shift(@xy),'r',$rr);      # outer radius

        @l2=$cp->smooth(shift(@xy),shift(@xy),shift(@xy),shift(@xy),$bossradius,$roe); 
        @xy=(@l2,@xy); 

        $gp->garccw('x',$xi+shift(@xy),'y',$yi+shift(@xy),'r',$roe);
        #         
        $gp->gmove('x',$xi+shift(@xy),'y',$yi+shift(@xy));              # line inwards
        $gp->garccw('x',$xi+shift(@xy),'y',$yi+shift(@xy),'r',$roe);
        
###     Actually we dont want to do this! The next point is always on the same arc, so this sometimes causes 
###     problems if we've already gone past this point, get an arc in wrong direction. This mitigates known bug 1. 
###        $gp->garcccw('x',$xi+shift(@xy),'y',$yi+shift(@xy),'r',$bossradius);
        shift(@xy), shift(@xy); ###
        
#       $gp->gmove('z',0.1); 
        $first=0; 
      } # all passes complete. 
     # repeat 1st move as z was being ramped up during this move. 
     $gp->garcccw('x',$xi+$tx,'y',$yi+$ty,'r',$bossradius,'z',$z); # rotation at boss radius, add in z incremen  
     $gp->grapid('z',0.1); 
     ($x,$y)=($tx,$ty); 
    # $x+=3*$cp->{cuttersize}*$tx/sqrt($tx**2+$ty**2);
    # $y+=3*$cp->{cuttersize}*$ty/sqrt($tx**2+$ty**2);


    # $gp->gcomment("This was designed to be where we take comp off but cant get it to work. so delay this till next move"); 
    # $gp->garccw('x',$xi+$x,'y',$yi+$y,'r',1.5*$cp->{cuttersize}); # to avoid problems with imaginary gauginging 
                                                                    # we move avay in arc at this point of twice radius of cutter. 
     $x=0.75*$bossradius*cos($t2);            
     $y=0.75*$bossradius*sin($t2); 
     $gp->gcomp0($gp->gmove('x',$xi+$x,'y',$yi+$y)); # 
    }
}
# private # 
sub cuthole
{            # diameter V

  
  my ($cp,$gp,$x,$y,$z,$size,$feed,$cuttersize)=@_; 

  return if (!defined($size) or $size<=0); 
  
  my $holesize=$cp->{holesize};
  $cuttersize ||= $cp->{cuttersize}; # can be optional, use wheel cutter if not supplied
  $gp->gcomment("Positioning for Hole"); 
  $gp->grapid('z',0.05); 
  $gp->grapid('x',$x,'y',$y); 
  $gp->grapid('z',$z); 
  $gp->gmove('x',$x,'y',$y,'z',$z,'f',$feed); 

  my ($passes,$passdepth)=($cp->{passes},$cp->{passdepth}); 

  if ($cp->{holedepth})
  {
    $passes=abs($cp->{holedepth}/$passdepth+1); 
    $passdepth=$cp->{holedepth}/$passes;
  }
  if ($holesize>$cuttersize) 
  {
     $gp->gcomment("Hole bigger than cutter");
     $holesize-=$cuttersize; # because we want to compensate for the size of the tool. 
     $gp->gmove('x',$x+$holesize/2,'y',$y); 
       
     my $passn=0; 
     while ($passn++ < $passes)
     {
        $gp->gcomment(sprintf("pass %d",$passn));
        $z+=$cp->{passdepth}; # passdepth negative
        $gp->garcccw('x',$x-$holesize/2,'y',$y,'r',$holesize/2,'z',$z,'f',$feed); 
        $gp->garcccw ('x',$x+$holesize/2,'y',$y,'r',$holesize/2); 
     } 
     $gp->garcccw('x',$x-$holesize/2,'y',$y,'r',$holesize/2,'z',$z); # we always redo this as z depth was being faded in during this arc. 
     $gp->gmove('x',$x,'y',$y); # move into center to avoid withdrawal while still in contact with work. 
  }
  else
  {  # else if holesize eq or less than cutter size, just do a plunge. 
     $z=$passdepth*$passes; 
     $gp->gmove('z',$z,'f',$feed); 
     $gp->gdwell('p',0.75);    
  } 

#  $gp->gmove('z', 0.05,$xs,$ys);
  $gp->gmove('z', 0.05); # return to surface
  $gp->gcomment("Hole done");
}

# debug
sub makepoint
{
  my ($gp,$x,$y,$d)=@_; # make a small arrow point. 
  $gp->gmove('x',$x+$d,'y',$y+$d,); 
  $gp->gmove('x',$x,'y',$y); 
  $gp->gmove('x',$x+$d,'y',$y-$d,); 
  $gp->gmove('x',$x,'y',$y); 
}  

# wheel - private
# Given any combination of $depth,$passes,$passdepth
# return a valid passes and passdepth. 
# eg        ($s->{holepassdepth},$s->{holepasses})=passdepth($s->{holepassdepth},$s->{holepasses},$s->{holedepth}); 
sub passdepth
{
  my ($w,$passdepth,$passes,$depth)=@_; 
  if (!defined($depth)) #  and !defined($passes and !defined($passdepth)
  {
  }
  elsif (defined($depth) and !defined($passes))  # passdepth must be def
  {
     $passes=abs($depth/$passdepth); 
     $passes=int($passes)+1 if ($passes!=int($passes)); 
     $passdepth=-abs($depth)/$passes;  
  }
  elsif (defined($depth) and defined($passes)) # ignore passdepth even if provided.  and !defined($passdepth)
  {
     $passdepth=-abs($depth)/$passes; 
  }
  return ($passdepth,$passes);   
}

sub cutset
{
  my ($w,$cuttersize,$passes,$passdepth)=@_; 
  my ($depth,$holedepth); 
  my ($h)=$cuttersize;
  
  if (ref($h) eq 'HASH') 
  { 
  
   ($cuttersize,$passes,$passdepth,$depth,$holedepth)=map { $h->{$_} } split(',',"cuttersize,passes,passdepth,depth,holedepth"); 
   $holedepth||=$depth;  
   ($passdepth,$passes)=$w->passdepth($passdepth,$passes,$holedepth);
  
  }
  $w->{cuttersize}=$cuttersize; 
  $w->{passdepth}=$passdepth; 
  $w->{passes}=$passes;  
  return $w;  
}

# previously cutwheel 
# public
sub cut
{
#   my ($x,$y,$z,
#       $m,$np,$nw,
#       $gr,$cp,$dd,$dw,
#       $dp,$pf,$ad,$ar,$feed)=@_; 
    
    # 1 cut dededum.
    
    my ($cp ,   # wheel 
        $gp,    # graphics package, either generate graphics or gcode
        $x,$y,$z,   # where to put the wheel 
        )=@_;

    $cp->{mm} or die;
    $pi or die;   

    return $cp->cycut($gp,$x,$y,$z) if ($cp->{cycloidal});   

    my $t=0; # theta, angle of wheel;
    my $ti=0.5*360/$cp->{n}; # half tooth increment.   
    $ti*= $pi/180;      # in radians now. 

    
 
                        # In some situations particularly pinions tooth and gap angles are not the same. 
                        # define twf as factor extra for tooth, less than 1 for a wider gap 
    my $tig=$ti*(2-$cp->{twf});  #  width of a gap in radians 
       $ti=$ti*$cp->{twf};       # this is now the width of a tooth. $tig+$ti is unchanged bu changes to $twf
    

    my ($xs,$ys,$zs)=($x,$y,$z);
    
    
    $gp->gmove('z',0.1,'f',$gp->{feed}); 

    $cp->cutbossindent($gp,$x,$y); 
    $cp->cuthole($gp,$x,$y,$z,$cp->{holesize},$gp->{feed});
    
    $cp->{ring}->cut($gp,$x,$y,$z) if ($cp->{ring}); 
    
    $cp->cuttrepan($gp,$xs,$ys,$zs);

    my $qtc=0.5*$cp->{mm}*$cp->{dw}*$pi/$cp->{n}; # quarter tooth circumference. 
    $x+=$cp->{mm}*$cp->{dw}*0.5;
    $y+= -$qtc; 
    $gp->gcomment("Move Away From Work"); 

    $gp->gmove('x',$x,'y',$y); 

#    $x-= $qtc;
    $y+= $qtc; 
#    $gp->gcompr('d',$gp->{toolnumber},$gp->garccw('x',$x,'y',$y,'r',$qtc)); 
    $gp->gcompr('d',$gp->{toolnumber},$gp->gmove('x',$x,'y',$y)); 

    $gp->gcomment("Start Cutting"); 
    $gp->gmove('z',$z+$cp->{passdepth}); 
    

    my $passes=0; 

     
    while ($passes++ < $cp->{passes})
    {
    my $tcount=0;
    my $t=0; 
    $z+= $cp->{passdepth}; 
    while ($t/2.0/$pi<0.999 ) 
    {

    $gp->gcomment(sprintf("Tooth number %d pass %d",++$tcount,$passes)); 
    
    $x-=$cp->{mm}*$cp->{dd}*cos($t);
    $y-=$cp->{mm}*$cp->{dd}*sin($t);
    # printf "G1 X$f Y$f Z$f F$ff\n", $x,$y,$z, $gp->{feed};    # radial stroke towards center of wheel
    
    $gp->gmove('x',$x,'y',$y,'z',$z,'f',$gp->{feed});
    

# 1st attempt, flat tooth bottom: 
#    $x+=$cp->{mm}*($cp->{dw}*0.5-$cp->{dd})*(cos($t+$tig)-cos($t));
#    $y+=$cp->{mm}*($cp->{dw}*0.5-$cp->{dd})*(sin($t+$tig)-sin($t));
#    printf "G3 X$f Y$f R$f F$ff\n",$x,$y,$mm*($dw*0.5-$dd),$gp->{feed};      # bottom of tooth, flat bottom 
#    $gp->gmove('x',$x,'y',$y); 

# 2nd attemt, circular bottom
#    $x+=$cp->{mm}*($cp->{dw}*0.5-$cp->{dd})*(cos($t+$tig)-cos($t));
#    $y+=$cp->{mm}*($cp->{dw}*0.5-$cp->{dd})*(sin($t+$tig)-sin($t));
#    $gp->garccw('x',$x,'y',$y,'r',$cp->{mm}*($cp->{dw}-2*$cp->{dd})*$tig/4,'f',$gp->{feed});  

# last attempt 2 quarter circ arcs
    my $dx=$cp->{mm}*($cp->{dw}*0.5-$cp->{dd})*(cos($t+$tig)-cos($t));
    my $dy=$cp->{mm}*($cp->{dw}*0.5-$cp->{dd})*(sin($t+$tig)-sin($t));
    $dx/=2.0; 
    $dy/=2.0; 

    my $dr=sqrt($dx*$dx+$dy*$dy);
    my $cr=$cp->{cuttersize}/2; # cutter radius

    my $crx1=($cr/$dr)*$dx; # a vector in the direction of the end of the tooth bottom, the size of the cutterradius. 
    my $cry1=($cr/$dr)*$dy;    

    my $crx2= -($cr/$dr)*$dy; # a vector normal to the other one, and roughly speaking inwards. 
    my $cry2=($cr/$dr)*$dx;    

    $x+=$crx1+$crx2; 
    $y+=$cry1+$cry2; 

    $gp->garccw('x',$x,'y',$y,'r',$cr);  

    $x+=((2*$dr-2*$cr)/$dr)*$dx; 
    $y+=((2*$dr-2*$cr)/$dr)*$dy;
    $gp->gmove('x',$x,'y',$y); # This bit is the flat part of the tooth bottom, after we've subtracted the radius of the cutter from each corner
                               # we have to program these moves as arcs to make the cutter move in this way because cutter compensation
                               # is on. 
    $x+=$crx1-$crx2;           # reverse out the deth of the cutter extra that we went
    $y+=$cry1-$cry2; 
  
    $gp->garccw('x',$x,'y',$y,'r',$cr);           


#    $x+=$dx+$dy
#    $y+=$; 
#
#     $x*= ($cp->{dw}*0.5-$cp->{dd}-$r)/($cp->{dw}*0.5-$cp->{dd});
#     $y*= ($cp->{dw}*0.5-$cp->{dd}-$r)/($cp->{dw}*0.5-$cp->{dd});
 
 #   $gp->garccw('x',$x,'y',$y,'r',$r,'f',$gp->{feed}); 


    $t+=$tig;
    $x+=$cp->{mm}*$cp->{dd}*cos($t);         # radial stroke outwards
    $y+=$cp->{mm}*$cp->{dd}*sin($t); 
    $gp->gmove('x',$x,'y',$y); 

    # addendum 
    # add in addendum height.

    $x+=$cp->{mm}*$cp->{ad}*cos($t);
    $y+=$cp->{mm}*$cp->{ad}*sin($t); 
    # rotate to middle of tooth, 0.25 of full tooth+gap  width. 
    $x+=$cp->{mm}*($cp->{dw}*0.5+$cp->{ad})*(cos($t+0.5*$ti)-cos($t));
    $y+=$cp->{mm}*($cp->{dw}*0.5+$cp->{ad})*(sin($t+0.5*$ti)-sin($t));
    $gp->garcccw('x',$x,'y',$y,'r',$cp->{mm}*$cp->{ar},'f',$gp->{feed}); 

    # back out the addendum height. 
    $x-=$cp->{mm}*$cp->{ad}*cos($t+0.5*$ti);
    $y-=$cp->{mm}*$cp->{ad}*sin($t+0.5*$ti); 
    # rotate a further half .25 tooth pitch 
    $x+=$cp->{mm}*($cp->{dw}*0.5)*(cos($t+$ti)-cos($t+0.5*$ti));
    $y+=$cp->{mm}*($cp->{dw}*0.5)*(sin($t+$ti)-sin($t+0.5*$ti));
    $gp->garcccw('x',$x,'y',$y,'r',$cp->{mm}*$cp->{ar},'f',$gp->{feed}); 

    $t+=$ti; 

    }
    }

    $gp->gmove('z',0.1);
    $gp->gcomp0(); 
    $gp->gmove('x',$xs,'y',$ys,'f',$gp->{feed}  ); 

   

    $cp->cutfillet($gp,$xs,$ys,$zs,$gp->{feed},$cp->{fpasses},$cp->{fpassdepth}) if ($cp->{fillet});

#    $gp->gend(); 
}

sub dist
{
   shift if (ref($_[0])); 
   my ($x1,$y1,$x2,$y2)=@_; 
   return sqrt(($x2-$x1)**2+($y2-$y1)**2);
}

# public 
#wheel
sub outerradius
# return the radius of a circle that contains the wheel including teeth
{ 

my ($w)=@_; 
my $r=($w->{dw}/2.0+$w->{ad})*$w->{mm};
printf "dw=%f ad=%f outerrad is %f\n",$w->{dw},$w->{ad},$r; 
return $r; 
}
# public 
sub innerradius
# return the radius of a circle that contains the wheel including teeth
{ 

my ($w)=@_; 
return ($w->{dw}/2.0-$w->{dd})*$w->{mm};
}

sub fillet
{
    my ($c ,   # wheel 
# optional parameters: 
        $npasses, 
        $passdepth,
        )=@_;     


  $c->{fillet}=1; # flag to say do fillet; 
  $c->{fpasses}=$npasses; 
  $c->{fpassdepth}=$passdepth;   
}
# Similar to cutwheel, except that this cuts away the little triangles left when the wheel has been cut out
# If you are cutting from a sheet, then its not necessary, but where you are not cutting the full deth, 
# eg cutting 2 wheels on top of each other, you need this to remove the triangular fillets
# theres scope for this to be much more comlex, and it may fail as it currently is. 
# (Ie its not a great algorithmn, but I've used it inthis form a couple of times. ) 
sub cutfillet
{
    my ($cp ,         # wheel 
        $gp,          # graphics package, either generate graphics or gcode
        $xi,$yi,$z,   # where to put the wheel 
        $feed,
    # optional parameters: 
        $npasses, 
        $passdepth
        )=@_;     
    
    my $cr=$cp->{mm}*$cp->{dw}/2-$cp->{cuttersize}*1.25; # radius to cut to. No attemt made to calcultate, its empirical 
    my $t=0; # theta, angle of wheel;
    my $ti=0.5*360/$cp->{n}; # half tooth increment.   
    $ti*= $pi/180;      # in radians now. 

    
 
                        # In some situations particularly pinions tooth and gap angles are not the same. 
                        # define twf as factor extra for tooth, less than 1 for a wider gap 
    my $tig=$ti*(2-$cp->{twf});  #  width of a gap in radians 
    $ti=$ti*$cp->{twf};       # this is now the width of a tooth. $tig+$ti is unchanged bu changes to $twf
    


##    my ($xs,$ys)=($x,$y);
    my ($x,$y);
    
    $gp->gmove('z',0.1,'f',$feed); 
    
    $npasses||=$cp->{passes}; 
    $passdepth||=$cp->{passdepth}; 
    
    my $passes=0;  
    while ($passes++ < $npasses)
    {
         
    my $tcount=0;
    my $t=-$ti/2; 
    $z+= $passdepth; 
    $x=($cp->{mm}*($cp->{dw}/2+$cp->{ad})+$cp->{cuttersize}/2)*cos($t);
    $y=($cp->{mm}*($cp->{dw}/2+$cp->{ad})+$cp->{cuttersize}/2)*sin($t);   # takes us to adendum point, comensates for cuttersize

    while ($t/2.0/$pi<0.999 ) 
    {
         
    $gp->gcomment(sprintf("Filleting Tooth number %d pass %d of %d",++$tcount,$passes,$npasses)); 
    
    $gp->gmove('x',$xi+$x,'y',$yi+$y); 
    $gp->gmove('z',$z);

    $t+=$ti/2+$tig/2;  
    my $tx=$cr*cos($t); 
    my $ty=$cr*sin($t); 

    $t+=$ti/2+$tig/2;  
  

    my $dx=($cp->{mm}*($cp->{dw}/2+$cp->{ad})+$cp->{cuttersize}/2)*cos($t)-$x; 
    my $dy=($cp->{mm}*($cp->{dw}/2+$cp->{ad})+$cp->{cuttersize}/2)*sin($t)-$y;    

    $x+=$dx/2; # this takes us to middle of gap, but by straight line, so cut off a bit more of that wedge
    $y+=$dy/2; 
    $gp->gmove('x',$x+$xi,'y',$y+$yi,'z',$z,'f',$feed);

    $gp->gmove('x',$tx+$xi,'y',$ty+$yi); 

    $gp->gmove('x',$x+$xi,'y',$y+$yi,'z',$z,'f',$feed);

    $x+=$dx/2; # this takes us to next addendum point 
    $y+=$dy/2; 

    }
    }

    $gp->gmove('z',0.1);
    $gp->gmove('x',$xi,'y',$yi); 

}

sub smooth
{
    # given a circle radius b and a point on circumference l2
    # the plan is to smooth the join between the line l1/l2  (each of these are points) and the circle circumference by 
    # replacing a bit of the line l1/l2 with a circle of radius r. 
    # The following are supplied where x1 y1 is l1 point 1, x2, y2 point 2 or l2.

    # so call with l1,l2,b ,r 
    # what comes back is l1 (unchanged), ,replacement l2 point sa which is start of arc, l1,sa are on the line 
    # l1,l2 but sa is nearer l1 than l2. 
    # ea where ea is on the original arc radius b, like l2, but is moved away from original l2. 
    # sa, ea can be joined with arc radius b.
 

    my ($w,$x1,$y1,$x2,$y2,$b,$r)=@_;

    # print "smooth x1=$x1,y1=$y1,x2=$x2,y2=$y2,b=$b,r=$r\n";

    #($x1,$y1,$x2,$y2,$b,$r)=(-0.2 , 0.2 , -0.707 , 0.707 , 1.0 , 0.1); 
#    ($x1,$y1,$x2,$y2,$b,$r)=   (-0.279378067455943, 0.65017874253593, 0.702760341741972, 0.0831408677831007, 0.9,0.1); 

    my $ks; 
  
    # straight line l1 l2 has eqn y=mx+c 

    my $m=($y2-$y1)/($x2-$x1); 
    my $c=$y1-($y2-$y1)*$x1/($x2-$x1); 
    $ks=$r>0?1:-1;  
#   $ks=-$ks if ($y2>0);
    $r=abs($r);  
    $ks=-$ks if ($x1<$x2);

    
    # line paralell to this and distance r away is y=mx+j where j=c+k or j=c-k 

    my $k = abs($r) * sqrt( (($x2-$x1)**2+($y2-$y1)**2)/($x2-$x1)**2); 
    my $j=$c+$k*$ks;  # ks is the sign of k from above. 

    # we need to solve this with the circle x^2+y^2=(b+r)^2
    # substituting for y in here gives 
    # 
    # x^2+y^2=(b+r)^2
    # y=mx+j
    # x^2+m^2x^2+2mxj+j^2=(b+r)^2
    # (1+m^2) x^2 + 2mj x +j^2-(b+r)^2=0 
    # use quadratic equation formula to find x: 
    # x=(-b+- sqrt(b^2-4ac)/2a
    #
    # x=(-2mj +- sqrt(4m^2j^2-4(1+m^2)(j^2-(b+r)^2)))/2(1+m^2)
    # This is the center point of the arc. 

    # s is the distance between c and l2, we now have x and y coords for both c and l2. 
    # u^2=s^2-r^2 and is distance from l2 in direction of l1  for the new l2 point at start of smoothing arc. 
    # The end of the arc is oc scaled such that distance is b, the radius of the circle. 
    $r=-$r if (dist(0,0,$x1,$y1)<$b);
    
    my $cxa=(-2*$m*$j + sqrt(abs(4*$m**2*$j**2-4*(1+$m**2)*($j**2-($b+$r)**2))))/2/(1+$m**2);
    my $cxb=(-2*$m*$j - sqrt(abs(4*$m**2*$j**2-4*(1+$m**2)*($j**2-($b+$r)**2))))/2/(1+$m**2);   # This is the other root of the quadratic. 
                                                                                        # use the one closest to l2? 
    my $cya=$m*$cxa+$j; 
    my $cyb=$m*$cxb+$j; 

    ($cxa,$cya,$cxb,$cyb)=($cxb,$cyb,$cxa,$cya) if (dist($x2,$y2,$cxb,$cyb)<dist($x2,$y2,$cxa,$cya)); # want nearest root to l2 .
    # swap rather than assign so that we still have the other root if we need to look at it for debug purposes.  

    my $s=dist($x2,$y2,$cxa,$cya);
    my $u=sqrt($s**2-$r**2);  
    my $sax=$x2+($x1-$x2)*$u/dist($x1,$y1,$x2,$y2);    #start of arc
    my $say=$y2+($y1-$y2)*$u/dist($x1,$y1,$x2,$y2); 
    my $eax=$cxa*$b/dist(0,0,$cxa,$cya); 
    my $eay=$cya*$b/dist(0,0,$cxa,$cya); 

    return ($x1,$y1,$sax,$say,$eax,$eay);              #ending on the circle

    # The code below is used for graphing out test cases. Its debug only. 
    my $gd=gdcode::new(undef,"test.png",6.0,2500,2500); 
    $gd->gmove('z',0.1);
    $gd->gmove('x',$x1,'y',$y1); 
    $gd->gmove('z',-0.1); 
    $gd->gmove('x',$x2,'y',$y2); 

    $gd->gmove('z',0.1);         
    $gd->gmove('x',0,'y',$b); 
    $gd->gmove('z',-0.1);             
    $gd->garcccw('x',0,'y',-$b,'r',$b); 
    $gd->garcccw('x',0,'y',$b,'r',$b); 


    $gd->gmove('z',0.1); 
    # ($cxa,$cya)=($cxb,$cyb);  # want to see the other one ? 
    $gd->gmove('x',$cxa+0.05,'y',$cya+0.05);             # mark the center with an X
    $gd->gmove('x',$cxa-0.05,'y',$cya-0.05,'z',-0.1); 
    $gd->gmove('x',$cxa+0.05,'y',$cya-0.05,'z',0.1); 
    $gd->gmove('x',$cxa-0.05,'y',$cya+0.05,'z',-0.1); 

#    $gd->gmove('x',$cxa,'y',$cya+$r,'z',0.1); 
#    $gd->garcccw('x',$cxa,'y',$cya-$r,'r',abs($r),'z',-0.1); 
#    $gd->garcccw('x',$cxa,'y',$cya+$r,'r',abs($r),'z',-0.1);

    
    $gd->gmove('x',$sax,'y',$say,'z',0.1); 
    $gd->garccw('x',$eax,'y',$eay,'r',abs($r),'z',-0.1);    


    $gd->gend(); 
    die; 
}
# This is a convienence wrapper funcion for smooth. 
# thing is parameter order depends on weather you are coming or going. 
# this function does the appropriate swap, both of the input parameters and the result
sub rsmooth
{
        my ($w,$x1,$y1,$x2,$y2,$br,$r)=@_;  # params are point1, point 2, bossradius, radius
        my @xy=($x2,$y2,$x1,$y1);           # point 1 and 2 given in wrong order for reverse smooth, so swap
        @xy=$w->smooth(@xy,$br,$r);         # xy now is  point, start of arc end of arc
        @xy=@xy[4,5,2,3,0,1];               # return start of arc, end of arc and point. 
        return @xy;                         # need in order given which is reverse, so give end of arc first
}

# this function returns dimentions in inches. 
# input can be a string such as 22mm, 72pt or 2.3i 
# output is somethig like 0.9, 1.0,2.3  as 22mm is about 0.9 inches, 72 points is exactly 1 inch and 2.3i means 2.3 inches.
# t is thousandths of an inch.  
sub dim
{
  my ($w)=shift;  # self pointer to wheel 
  my @a= map 
  { 
 
  s/i//g; 
  s/mm//g and $_=$_*$w->{mm};  
  s/pt//g  and $_=$_/72; 
  s/t//g  and $_=$_/1000; 
  $_; 

  } @_;
  return $a[0] if (@a==1);
  return @a; 
}
# this function returns dimentions in radians
# input can be a string such as 0.01r 5d or 5
# default units are degrees. 
# note that additional multipliers are allowd but ignore, so you can add an r to make the defult into radians, 
# but if degrees is specified, we get 5dr and this is interpreted as degrees as is 5dd. 
# Output is always in radians. 

sub dimr
{
  my ($w)=shift;  # self pointer to wheel 
  my @a= map 
  { 
    if (m/([dr])/i)
    { 
      my $d=$1; 
      s/[dr]//ig; 
      if ($d eq 'd') 
      { 
        $_=$_*$pi/180.0; 
      } 
    } 
    else 
    { 
      $_=$_*$pi/180.0; 
    }
    $_; 

  } @_;
  return $a[0] if (@a==1); # for scalar context, need to return a scalar. 
  return @a; 
}

# parameters: 
# toothradiuspc and toothradius used only when topshape is bicirc circlead circtrail 
package Grahamwheel;

use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.05;  
	 
@ISA=('Wheel'); 

sub new
{
  my (
      $class,   # self pointer; 
      $n,       # hash (now)
      )=@_; 

#die "$d,$dd";


my $s={};
shift;  
if (ref($n))  #  means we've been passed a hash ref
{ 
  my $h=$n; 
  
  for my $key (qw(lift nteeth externald toothdepth toothtoppc toothtop toothbase toothbasepc offset holesize topshape toothradius toothradiuspc filletradius )) 
  { 
     $s->{$key}=$h->{$key}; 
  } 
  $s->{n}=$s->{nteeth}; delete $s->{nteeth}; 
  $s->{d}=$s->{externald}; delete $s->{externald}; 
  $s->{dd}=$s->{toothdepth}; delete $s->{toothdepth};  
}
else
{
  die "You need to pass a hash reference to the Graham wheel constructor"; 
#   map { $s->{$_}=shift } qw(n d dd offset toothbase toothtop  topshape topshape); 
}


#$d=$s->dim($d); 
#$dd=$s->dim($dd);
#$offset||=-6; 
#$offset=$s->dimr($offset); 
#$toothbase||=33.333; # in %
#$toothbase/=100.0;  # as a proportion . 
#$toothtop||=0.5; # in degrees
#$toothtop=$s->dimr($toothtop); 

bless $s, $class;

$s->{d}=$s->dim($s->{d}); 
$s->{dd}=$s->dim($s->{dd});
$s->{offset}||=-6; 
$s->{offset}=$s->dimr($s->{offset}); 
$s->{toothbase}||=$s->{toothbasepc}; # synonym. 
$s->{toothbase}/=100.0; # convert to proportion. 
$s->{toothtop}||=0.5;  # in degrees
$s->{toothtop}=$s->dimr($s->{toothtop}); # now in radians. 
if ($s->{toothtoppc} > 0.01)
{ 
   $s->{toothtop}=$s->{toothtoppc}*0.02*$pi/$s->{n}; 
}

$s->{topshape}||='semi'; 

if (!grep { $s->{topshape} eq $_} qw(semi flat circ bicirc circlead circtrail)) 
{ 
  die "unknown topshape '$s->{topshape}'"; 
}
$s->{dw}=($s->{d}-$s->{dd}*2)/$mm; # we set tis so trepanning works. This is a total fudge!  


return $s; 
}
# given line p1,p2, and line p3, p4 find cross point. 
sub solve
{
  my ($w,$x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4)=@_; 

  my ($m1,$m2,$k1,$k2,$t1); 

  $m1=($x3-$x4)/($x1-$x2);
  $k1=($x4-$x2)/($x1-$x2); 
 
  $m2=($y3-$y4)/($y1-$y2);
  $k2=($y4-$y2)/($y1-$y2);

  $t1=($k1-$k2*$m1/$m2)/(1-$m1/$m2);


  my ($x,$y); 

  $x=$t1*$x1+(1-$t1)*$x2; 
  $y=$t1*$y1+(1-$t1)*$y2;

  return ($x,$y); 

}

sub ttr 
{
  my ($w,$gp,$pr)=@_;
  my ($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4)=@$pr;
#
#    p2/ |p3   4 points with x y cords as in diagram. Calculating radius of circle 
#     /  |     tat will join p2 p3. 
#  p1/   |p4
#  _/    |_
#
#
#

# calclate bisector point of angle p1 p2 p3
# method, make unit vector in direction of lines, make point half way between ends of vectors. (half point for 2, hp2) 
# make vector from p2 to half way point. 
# repeat with p4p3p2
# cross vectors to get circle center point 

#solve($w,2.5,5.2,6.8,2.9,1.0,0,6.8,0);
#exit; 

$gp->gline($x1,$y1,$x2,$y2); 
$gp->gline($x3,$y3,$x4,$y4); 

# This is a unit vector in the x1 x2 direction
my $u21x=($x1-$x2)/sqrt(($x1-$x2)**2+($y1-$y2)**2);
my $u21y=($y1-$y2)/sqrt(($x1-$x2)**2+($y1-$y2)**2);

# $gp->gline($x2,$y2,$x2+$u21x,$y2+$u21y);


# This is a unit vector in the x3 x2 direction  
my $u23x=($x3-$x2)/sqrt(($x3-$x2)**2+($y3-$y2)**2);
my $u23y=($y3-$y2)/sqrt(($x3-$x2)**2+($y3-$y2)**2);

#$gp->gline($x2,$y2,$x2+$u23x,$y2+$u23y);

# A point half way between unit vectors gives the angle bisector. 
my $hp2x=$x2+0.5*($u21x+$u23x); # gives angle bisecor point as absolute coord. 
my $hp2y=$y2+0.5*($u21y+$u23y);

#$gp->gline($x2,$y2,$hp2x,$hp2y);


my $u34x=($x4-$x3)/sqrt(($x4-$x3)**2+($y4-$y3)**2);
my $u34y=($y4-$y3)/sqrt(($x4-$x3)**2+($y4-$y3)**2);

my $u32x=-$u23x;
my $u32y=-$u23y; 

# The other angle bisected. 
my $hp3x=$x3+0.5*($u32x+$u34x); # gives angle bisecor point as absolute coord. 
my $hp3y=$y3+0.5*($u32y+$u34y);


#$gp->gline($x3,$y3,$hp3x,$hp3y);


# Where these two angle bisectors cross, gives us the circle center. 
my ($cx,$cy)=$w->solve($x2,$y2,$hp2x,$hp2y,$x3,$y3,$hp3x,$hp3y); 




# cosine of the angle at p1 by the cosine rule. 
my $ca1=(($cx-$x2)**2+($cy-$y2)**2-($x1-$x2)**2-($y1-$y2)**2-($cx-$x1)**2-($cy-$y1)**2)/
        (-2*sqrt((($x1-$x2)**2+($y1-$y2)**2)*(($cx-$x1)**2+($cy-$y1)**2)));


# length from p1 to the normal point 
my $l1 =$ca1*sqrt((($cx-$x1)**2+($cy-$y1)**2)); 

# proportion down the line from x1 to normal point
my $t=$l1/sqrt(($x1-$x2)**2+($y1-$y2)**2); 

# this is the normal point, and we replace x2, y2 with this new point. 
my $mx2=$x1*(1-$t)+$x2*$t; 
my $my2=$y1*(1-$t)+$y2*$t; 


# do the same to calculate x3 y3 replacement oint
my $ca2=(($cx-$x3)**2+($cy-$y3)**2-($x3-$x4)**2-($y3-$y4)**2-($cx-$x4)**2-($cy-$y4)**2)/
        (-2*sqrt((($x3-$x4)**2+($y3-$y4)**2)*(($cx-$x4)**2+($cy-$y4)**2)));

my $l2 =$ca2*sqrt((($cx-$x4)**2+($cy-$y4)**2)); 

   $t=$l2/sqrt(($x3-$x4)**2+($y3-$y4)**2); 

my $mx3=$x4*(1-$t)+$x3*$t; 
my $my3=$y4*(1-$t)+$y3*$t; 

# calculate the radius. For best acuracy, we average these, probably not necessary. 
my $r=(sqrt(($cx-$mx2)**2+($cy-$my2)**2)+sqrt(($cx-$mx3)**2+($cy-$my3)**2))/2; 

# replace the points
@$pr=($x1,$y1,$mx2,$my2,$mx3,$my3,$x4,$y4);

# return the radius. 
return $r; 
}


# grahamwheel cut
sub cut
{

    my ($cp ,    # wheel 
        $gp,        # graphics package, either generate graphics or gcode
        $x,$y,$z,$theta    # where to put the wheel 
        )=@_;  


my $ti =2*$pi/$cp->{n};           # tooth and gap angular increment.   
my $tig=(1-$cp->{toothbase})*$ti; # tooth increment for gap (angular) 
my $tt = $cp->{toothbase}*$ti;    # tooth angular increment. 


my $topshape=$cp->{topshape}; 
my $toothtop=$cp->{toothtop};        # anglar size of toothtop
my $filletradius;
$filletradius=0.02; 
$filletradius=0.03125; # corresponds to exactly 1/16 inch cutter 
$filletradius=0.033; # in practice make slightly larger
$filletradius=$cp->{filletradius}; # This is the radius used at the bottom of the tooth gap, needs to be as small as possible, but bigger than the cutter 
                                   # radius used, or else it cant be cut!

$cp->{filletradius} or die; 
my $ccrunin=3*$cp->{cuttersize};  # distance used for compensation run in. 
                                                                    
# printf  "cos offset=%f offset=%f\n",cos($cp->{offset}),$cp->{offset};

$cp->{d}-=$cp->{d}*$toothtop*cos($cp->{offset}*$cp->{n}/5) if ($topshape eq 'semi'); 
# 5 is an empiricle fudge factor in the above
# purpose of this is to prevent the semicircle at the top of each tooth increasing diameter of wheel. 


my ($xs,$ys,$zs)=($x,$y,$z); # remember initial place.
$gp->gcomment("Graham Wheel");  
$gp->gmove('z',0.1,'f',$gp->{feed});
$cp->cutbossindent($gp,$x,$y); 
$cp->cuthole($gp,$x,$y,$z,$cp->{holesize},$gp->{feed});
$cp->{ring}->cut($gp,$x,$y,$z) if ($cp->{ring});
$cp->cuttrepan($gp,$xs,$ys,$zs);


my $ri=$cp->{d}*0.5-$cp->{dd}; # inner radius
my $ro=$cp->{d}*0.5;           # outer radius  


my $passes=0; 
my $feed=3*$gp->{feed}; # faster for positioning, should really be grapid. 
my $offset=$cp->{offset}; 
my $first=1; 
my $lift=$cp->{lift}; 

$theta=$cp->dimr($theta); # convert radians, default degrees. 

$gp->gcomment("Graham Wheel - teeth");  
while ($passes++ < $cp->{passes})
    {
    my $tcount=0;
    my $t=$tig/2+$theta;     # start half way through gap 
    my (@toothgap); 
    $z+= $cp->{passdepth}; 
    while ($t<2*$pi+$theta ) 
    {
     my @xy; 

    $gp->gcomment(sprintf("Tooth number %d pass %d",++$tcount,$passes)); 



    $x=$ri*cos($t); 
    $y=$ri*sin($t); 

    if ($first)
    { 
      $first=0; 
      $gp->gmove('x',$xs+$x,'y',$ys+$y-$ccrunin,$feed);
      $gp->gcompr('d',$gp->{toolnumber},$gp->gmove('x',$xs+$x,'y',$ys+$y,$feed));
#      $gp->gmove('z',$z,$gp->{feed});        # pen down, slow feed
      $first=0; 
    } 
    else
    {
      $gp->gmove('x',$xs+$x,'y',$ys+$y,'f',$gp->{feed});   # inner circumference, 1st point
      $gp->gmove('z',$z,$gp->{feed});        # pen down, slow feed
    }
  #  $feed=$cp->{d}*0.5-$cp->{dd};  
                                           # 2nd half of tooth gap 
    $t+=$tig/2;
    $x=$ri*cos($t); 
    $y=$ri*sin($t); 

    @xy=(); 
    push(@xy,$x,$y); 
#    $gp->garcccw('x',$x,'y',$y,'r',$ri);  # to end of toothgap
 
#    $x+=($ro-$ri)*cos($t+$offset)/cos($offset);   # top of tooth. 
#    $y+=($ro-$ri)*sin($t+$offset)/cos($offset); 

# to top of tooth: 

     
     my $td=$tt-$toothtop;  # Differencce in angular size of top and bott of tooth, ensures that a tapered tooth is symetric 
     $x=($lift+$ro)*cos($t+$offset+$td/2); 
     $y=($lift+$ro)*sin($t+$offset+$td/2); 
     

 
    

    push(@xy,$x,$y);                       # leading edge of tooth 
    @toothgap=(); 
    push(@toothgap,@xy);                   # for toothgap calculation

    
    @xy=$cp->rsmooth(@xy,$ri, -1*$filletradius);  
   
    $gp->garcccw('x',$xs+shift(@xy),'y',$ys+shift(@xy),'z',$z,'r',$ri);  # to end of toothgap
    $gp->garccw('x',$xs+shift(@xy),'y',$ys+shift(@xy),'r',$filletradius);  # draw fillet
    
   
    $x=($ro)*cos($t+$toothtop+$offset+$td/2);
    $y=($ro)*sin($t+$toothtop+$offset+$td/2);
    # print "lift=$lift, ro=$ro ri=$ri\n"; 
   
    
    @xy=(); 
    push(@xy,$x,$y);                              # 1st point of trailing edge
    
  
    $t+=$tt; 
    $x=$ri*cos($t); 
    $y=$ri*sin($t); 
         
    #$gp->gmove('x',$x,'y',$y);                   # draw trailing edge of tooth
    push(@xy,$x,$y);                              # 2nd point of trailing edge
    push(@toothgap,@xy);                          # for toothgap calculation

    my $toothtopradius=$cp->ttr($gp,\@toothgap) if ($topshape eq 'semi'); 
    
    $t+=$tig/2;
    $x=$ri*cos($t); 
    $y=$ri*sin($t); 

    @xy=$cp->smooth(@xy,$ri,$filletradius); 

    shift(@xy); shift(@xy); 

    my $toothtopdist=$cp->dist(@toothgap[2..5]); 
    my $toothradius;
    $toothradius=0.005*$cp->{toothradiuspc}*$toothtopdist; # 100% means half the total width of tooth. 
    $toothradius||=$cp->{toothradius}; 
    
    # should be flat circ bicirc circlead circtrail semi
    if ($topshape eq 'flat')
    { 
      $gp->gmove('x',$xs+$toothgap[2],'y',$ys+$toothgap[3]);                    # draw leading edge of tooth
      $gp->gmove('x',$xs+$toothgap[4],'y',$ys+$toothgap[5]);                    # draw toothtop  flat 
    }
    elsif ($topshape eq 'circ')
    {
      $gp->gmove('x',$xs+$toothgap[2],'y',$ys+$toothgap[3]);                    # draw leading edge of tooth
      $gp->garcccw('x',$xs+$toothgap[4],'y',$ys+$toothgap[5],'r',$ro);          # draw circular shaped tooth top   
    }
    elsif ($topshape eq 'bicirc')
    {
      my @bc;   
      @bc=@toothgap[0..3]; 
      @bc=$cp->smooth(@bc,$ro,-$toothradius);
      shift(@bc);shift(@bc); 
          
      $gp->gmove('x',$xs+shift(@bc),'y',$ys+shift(@bc));                    # draw leading edge of tooth
      $gp->garcccw('x',$xs+shift(@bc),'y',$ys+shift(@bc),'r',$toothradius);         # draw rounded edge
      @bc=@toothgap[4..7];
      @bc=$cp->rsmooth(@bc,$ro,$toothradius);
      $gp->garcccw('x',$xs+shift(@bc),'y',$ys+shift(@bc),'r',$ro);      # draw circular shaped tooth top
#     $gp->gmove('x',$xs+shift(@bc),'y',$ys+shift(@bc);                 # draw flat shaped tooth top
      $gp->garcccw('x',$xs+shift(@bc),'y',$ys+shift(@bc),'r',$toothradius);         # draw rounded edge      
    }
    elsif ($topshape eq 'circlead') 
    {
      my @bc; 
 
       $gp->gmove('x',$xs+$toothgap[2],'y',$ys+$toothgap[3]);                    # draw leading edge of tooth
     
      @bc=@toothgap[4..7];
      @bc=$cp->rsmooth(@bc,$ro,$toothradius);
      $gp->garcccw('x',$xs+shift(@bc),'y',$ys+shift(@bc),'r',$ro);               # draw circular shaped tooth top
      # $gp->gmove('x',$xs+shift(@bc),'y',$ys+shift(@bc));                       # draw flat  shaped tooth top
       
      $gp->garcccw('x',$xs+shift(@bc),'y',$ys+shift(@bc),'r',$toothradius);         # draw rounded edge      
    }
    elsif ($topshape eq 'circtrail')
    {
      my @bc; 
      push(@bc,@toothgap[0..3]); 
      @bc=$cp->smooth(@bc,$ro,-$toothradius);
      shift(@bc);shift(@bc); 
      
      
      $gp->gmove('x',$xs+shift(@bc),'y',$ys+shift(@bc));                    # draw leading edge of tooth
      $gp->garcccw('x',$xs+shift(@bc),'y',$ys+shift(@bc),'r',$toothradius);  # to end of toothgap toothgap 
      $gp->garcccw('x',$xs+$toothgap[4],'y',$ys+$toothgap[5],'r',$ro);                  # draw circular shaped tooth top   flat 
    }
   else # if semi  
    {
     $gp->gmove('x',$xs+$toothgap[2],'y',$ys+$toothgap[3]);                    # draw leading edge of tooth
     $gp->garcccw('x',$xs+$toothgap[4],'y',$ys+$toothgap[5],'r',$toothtopradius); # draw semi-circulular-type tooth top
    }
    $gp->gmove('x',$xs+shift(@xy),'y',$ys+shift(@xy));  
    $gp->garccw('x',$xs+shift(@xy),'y',$ys+shift(@xy),'r',$filletradius);  # draw fillet

    $gp->garcccw('x',$xs+$x,'y',$ys+$y,'r',$ri);         # draw 2nd half of tooth gap 
   # $gp->gend(); exit; 

   }
}

$gp->gmove('z',0.1);
$gp->gcomp0($gp->gmove('x',$xs+$x,'y',$ys+$y+$ccrunin));         # compensation off 
$gp->grapid('x',$xs,'y',$ys,'f',$gp->{feed}  ); 
# $cp->cutfillet($gp,$xs,$ys,$zs,$gp->{feed},$cp->{fpasses},$cp->{fpassdepth}) if ($cp->{fillet});
}

package Grahamyoke; 
use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.05;  

@ISA=('Wheel'); 

sub new
{
  my (
      $class,      
      $n,       # a hash reference containing other parameters
      )=@_; 
# die "$s , $n,".ref($n);
my $s={};
if (ref($n) eq 'HASH')  #  means we've been passed a hash ref
{ 
  my $h=$n; 
  
  # leradius - leading edge radius left and right, 0 or undef for none. 
  # droopangle - angle from horizontal of main structure of each side eof the yoke.  
  for my $key (qw(liftl liftr lift rl rr r armwidth width innerradius outerradius topradius botradius anglel 
                  angler angle holesize leradiusl leradiusr leradius droopanglel droopangler droopangle)) 
  { 
     $s->{$key}=$h->{$key}; 
  } 
}
else
{
  die "A hash reference is required for new $class got ".ref($n);
}


# and check units of linear things 
for my $key ( qw(r armwidth width innerradius outerradius botradius topradius holesize leradius ))
{
   $s->{$key}=Wheel::dim(undef,$s->{$key});
}

$s->{droopangler}||=$s->{droopangle}; 
$s->{droopanglel}||=$s->{droopangle}; 
$s->{angler}||=$s->{angle}; 
$s->{anglel}||=$s->{angle}; 
$s->{liftr}||=$s->{lift}; 
$s->{liftl}||=$s->{lift};
$s->{rl}||=$s->{r}; 
$s->{rr}||=$s->{r}; 
$s->{leradiusl}||=$s->{leradius};
$s->{leradiusr}||=$s->{leradius};



# make sure that things that are angles have default input in degrees, but can have radians if we want. 
for my $key ( qw(liftl liftr anglel angler angle droopanglel droopangler))
{
   $s->{$key}=Wheel::dimr(undef,$s->{$key});
}


my $cos="";  # cosmetic check.  
  for my $key (qw(innerradius outerradius topradius botradius)) # these are all cosmetic, and may be specified as % in which case it is % of width  
  {
    $cos.=$s->{$key}; 
    $s->{$key}*=$s->{width}/100.0 if ($s->{$key}=~s/%//); 
  }
$s->{armwidth}==0 and  $s->{armwidth}=$s->{width}; 
$s->{width}==0 and $cos=~/%/ and die "You are using % and yet width is zero. % refer to width in new grahamyolk!"; 

for my $key (qw(innerradius outerradius topradius botradius)) # these are all cosmetic, and may be specified as % in which case it is % of width  
{
    $s->{$key}*=$s->{width}/100.0 if ($s->{$key}=~s/%//); 
}




# correction for the width of the arm, increases the angle.
my $ac=0; 
$ac=atan2($s->{armwidth}/2,($s->{rl}+$s->{width})); 
$s->{anglel}+=$ac;
$s->{droopanglel}-=$ac; 
$ac=atan2($s->{armwidth}/2,($s->{rr}+$s->{width})); 
$s->{angler}+=$ac;
$s->{droopangler}-=$ac; 

bless $s, $class;

return $s; 
}

sub definehalfyoke
{
  my ($cp,$gp,$x,$y,$z,$theta,
      $width,
      $armwidth,
      $droopangle,
      $liftouter,
      $liftinner,
      $angle,
      $innerpr,
      $outerpr,
      $innerradius, 
      $outerradius,
      $innerlength

)=@_; 


my ($xs,$ys,$zs)=($x,$y,$z); 
my $p=Profile->new();

$y+=$armwidth/2/cos($droopangle);

$p->ppush($x,$y); 
$p=$p->rotate(-$droopangle,$xs,$ys);
$y=$ys+$armwidth/2;  


$p->comment("Top left or right corner"); 
$p->ppush($x-sqrt(($innerlength+$width)**2-$armwidth*$armwidth/4),$y); # locates extreme nw corner 

$x-=$innerlength+$width;
$y-=$armwidth/2;          # back onto center line 


$p=$p->rotate(-$angle-$liftouter,$xs,$ys); 


$p->comment("Outermost arc of yoke"); 
$p->ppush($x,$y,$innerlength+$width,1);
$p=$p->smooth($outerradius,$xs,$ys) if ($outerradius); 

$p=$p->rotate(+$liftouter-$liftinner,$xs,$ys); 
$x+=$width; 

$p->comment("Pallete surface"); 
$p->ppush($x,$y);


my $a=$angle-atan2($armwidth,2*$innerlength)+$liftinner; # This is the angle to return. 
                 # Its less than angle because we need to take off half the arm width. 
$p=$p->rotate($a,$xs,$ys);
$p=$p->smooth($outerpr,$xs,$ys) if ($outerpr); 
$p->comment("Innermost arc of yoke."); 
$p->ppush($x,$y,$innerlength,0);  # draw inner surface, curved centered on xs,ys. 
$p=$p->smooth($innerpr,$xs,$ys) if ($innerpr); 
$p=$p->rotate(atan2($armwidth,2*$innerlength),$xs,$ys); 
$y-=$armwidth/2/cos($droopangle);
$p=$p->rotate($droopangle,$xs,$ys); 
$p->ppush($xs,$y); 
$p=$p->smooth($innerradius,$xs,$ys) if ($innerradius); 
$p=$p->rotate($theta,$xs,$ys) if ($theta); 
return $p; 
  
}
# graham yoke
sub cut
{

    my ($cp ,          # Wheel , the self pointer 
        $gp,              # graphics package, either generate graphics or gcode
        $x,$y,$z,$theta   # where to put the Wheel, and an extra rotation cw in radians  
        )=@_;  


my $ccrunin=3*$cp->{cuttersize};  # distance used for compensation run in.
my $fastfeed=3*$gp->{feed};       # faster for positioning, should really be grapid. 

my ($xs,$ys,$zs)=($x,$y,$z); # remember initial place. 
$gp->gcomment("Graham Yoke at $x,$y"); 
$gp->gmove('z',0.05,'f',$gp->{feed});
$cp->cuthole($gp,$x,$y,$z,$cp->{holesize},$gp->{feed});

$gp->gcomment("Graham Yoke at $x,$y"); 
$theta=$cp->dimr($theta); 

my $rl=$cp->{rl};
my $width=$cp->{width};  


my $p=$cp->definehalfyoke($gp,$x,$y,$z,$theta,
                        $cp->{width},
                        $cp->{armwidth},
                        $cp->{droopanglel},
                        $cp->{liftl},
                        0,
                        $cp->{anglel},
                        $cp->{leradiusl},
                        0,
                        $cp->{innerradius},
                        $cp->{outerradius},
                        $cp->{rl}
                       ); 


print "left hand side \n"; 
$p->print(); 

my $q=$cp->definehalfyoke($gp,$x,$y,$z,-$theta,
                        $cp->{width},
                        $cp->{armwidth},
                        $cp->{droopangler},
                        0,
                        $cp->{liftr},
                        $cp->{angler},
                        0,
                        $cp->{leradiusr},
                        $cp->{innerradius},
                        $cp->{outerradius},
                        $cp->{rr}
                       ); 

print "right hand side \n"; 
$q->print();                   
$q=$q->move(-$xs,0)->mirrory()->reverse()->move($xs,0);
print "After flip...\n"; 
$q->print();
$p->comment("Second half-yoke"); 
$p->ppush($q);
print "After add...\n"; 
$p->print();  

$p->movestartfin();
$p->movestartfin();

$p->dedupe(); 
 
$p->linesmooth($cp->{topradius},@{$p->{points}}-2)     if ($cp->{topradius}); 
$p->linesmooth(-$cp->{botradius},(@{$p->{points}})/2-2) if ($cp->{botradius}); 


#my @first=$p->shift(); 
my @first=$p->points(0); 
$gp->gmove('x',$first[0]+$ccrunin,'y',$first[1]);
$gp->gcompr('d',$gp->{toolnumber},$gp->gmove('x',$first[0],'y',$first[1]));  
$p->plot($gp,$z,$cp->{passes},$cp->{passdepth},0); 
$gp->gcomp0($gp->gmove('x',$first[0]+$ccrunin,'y',$first[1])); 

return; 
}

# end of grahamyoke
#################################

# This is used for creating one piece of metal with 2 or more components vertically stacked on top of each other. 
package Stack;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.05;  


sub new
{
    my ($t,$cuttersize,$passes,$passdepth,$facedepth)=@_; 
    my $s={}; 
    my @c; 
    $s->{c}=\@c;
    $s->{cuttersize}=$cuttersize; 
    $s->{passdepth}=$passdepth;
    $s->{facedepth}=$facedepth if ($facedepth); 
    $s->{passes}=$passes;   
    return bless $s,$t; 
}

sub add
{
  my ($s,@c)=@_; 

  my $c=$s->{c}; 
 
  push(@$c,@c); 
            
}
sub insert
{
  my ($s,@c)=@_; 

  my $c=$s->{c}; 
  unshift(@$c,@c); 
}

sub objects
{
  my ($s)=@_; 

  return @{$s->{c}}; 
}

sub objectcount
{
  my ($s)=@_; 
  my $n=scalar($s->objects()); 
  return $n;  
}
# stack 
sub cut
{
  my ($s,$g,$x,$y,$zi)=@_; 
  my (@r);
  my (@s); 
  my (@f) ; 
  my ($z); 

  my @c=$s->objects(); 
  for my $i (0..$#c)
  {
    
     if ($i !=$#c)
     {
       printf "i is $i type %s or is %f \n",ref($c[$i]),$c[$i]->outerradius();

       my $r=$c[$i]->{ring}=Ring->new($s->{cuttersize},$c[$i]->passes(),
                   $c[$i]->passdepth(),$c[$i]->outerradius(),$c[$i+1]->outerradius(),
            $z); 
       $r->{name}="ring4item $i"; 
       
       $z=$zi; 
    }
  }

  $z=$zi; 
  for my $c ($s->objects())
  {
    $c->{z}=$z; 
    $z+=$c->passes()*$c->passdepth(); 
  }

  # resize the non-facing cuts. 
    
  for my $i (0..$#c-1)
  {
     printf "Outerradius is %f\n", $c[-1]->outerradius();
     $c[$i]->{ring}->widen($c[-1]->outerradius()+$s->{extra}) if ($c[$i]->{ring}); 
     
  }
  
  
  for my $c (@r,@f,$s->objects())
  {
    $c->{ring}->cut($g,$x,$y,$c->{z}) if ($c->{ring}); 
    $c->{ring}=""; 
    if ($c->{holesize} )
    {
      $c->{holedepth}+=$zi; 
      $c->cuthole($g,$x,$y,0,$c->{holesize},$g->{feed},$s->{cuttersize});
      $c->{holesize}=undef; 
      $c->{holedepth}=0.0;
    }
  } 

  for my $c (@r,@f,$s->objects())
  {
    printf "stack cut object is %s cutting at z=$c->{z}\n", ref($c); 
    $c->cut($g,$x,$y,$c->{z}); 
  } 
}
package CNC::Cog; 
use vars qw($VERSION @ISA @EXPORT);
@ISA=qw(Cog); 

package Cog; 
use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.05;  

	
my $inches="inches"; 
my $f="%9f  "; 
my $ff="%2.1f";   # for feed rate; 

sub newcogpair                                         
{
    my ($this,$m,$np,$nw)=@_;
    my ($dpi);
     
    ($m,$np,$nw,$dpi)=map { $m->{$_} } ('module','np','nw','pitch','dpi') if (ref($m) eq 'HASH');
    $m=1/($dpi*$mm) if (!defined($m) and defined ($dpi));
 
    @_==4 or main::confess("wrong number of paremeters");
    my $cogpair=bless {};

    my ($w,$p); 

    $w=$cogpair->{wheel}=Wheel->new($m,$nw);
    $p=$cogpair->{pinion}=Wheel->new($m,$np);
    my $af=$cogpair->{af}=addendumFactor($np,$nw);

    $p->{pa}=$w->{pa}=$cogpair->{pa}=0.95*$af;  #practical addendum  factor
    $cogpair->{gr}=$np/$nw;#gear ratio
    $p->{cp}=$w->{cp}=$cogpair->{cp} = $m * $pi ;   # circular pitch
    $w->{dd}=$cogpair->{dd} = $m * $pi/2 ;
    $p->{dd}=$m*($af*0.95+0.4); # BSI rule for dd height for pinion. 
    $w->{dw}=$cogpair->{dw} = $m * $nw ;
    $p->{dw}=$cogpair->{dp} = $m * $np ;
#    $p->{ad}=$w->{ad}=$cogpair->{ad} = $m * 0.95 * $af ;
    $w->{ad}=$cogpair->{ad} = $m * 0.95 * $af ;
    $w->{ar}=$cogpair->{ar} = $m * 1.40 * $af ; 
    $w->{twf}=1.0;     # tooth width factor

    if ($p->{n}>=10)
    {
    # pinion profile A
    $p->{ar}=$m*0.525 ; 
    $p->{ad}=$m*0.525; 
    }
    elsif ($p->{n}==8 or $p->{n}==9)
    {
     # profile B. 
     $p->{ar}=$m*0.70 ; 
     $p->{ad}=$m*0.67; 
    }
    elsif ($p->{n}==6 or $p->{n}==7)
    {
      # profile C 
     $p->{ar}=$m*1.05; 
     $p->{ad}=$m*0.855; 
    }
    if ($p->{n}>=11) # set up special tooth width profile for pinion. 
    {
      $p->{twf}=1.25/1.57; 
    }
    else
    {
      $p->{twf}=1.05/1.57;       
    }

    $w->{mm}=$p->{mm}=$cogpair->{mm} = 1.0/25.4;   # 1.0/24.8; 
    $cogpair->{nw}=$nw;
    $cogpair->{np}=$np; 

    return $cogpair; 
}

sub addendumFactor
{   
    my ($np,$nw)=@_;
    my  $b  = 0.0 ;
    my  $t0 = 1.0 ;
    my  $t1 = 0.0 ;
    my  $r2 = 2 * $nw/$np ;
    my  $errorLimit=0.000001;
    $pi or die "pi is not set!"; 
    while (abs($t1 - $t0) > $errorLimit)
        {   $t0 = $t1;
            $b = atan2(sin($t0), (1 + $r2 - cos($t0))) ;
            $t1 = $pi/$np + $r2 * $b ;   
        }
    return 0.25 * $np * (sin($t1)/sin($b) - $r2);
}
# cog
# set up some default parameters: carry these through to the individuel wheels. 
sub cutset
{
  my ($cp)=shift(@_); 

  $cp->{wheel}->cutset(@_); 
  $cp->{pinion}->cutset(@_); 
  return $cp; 
}

##### end of package cog 

package Ring;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.05;  
	 
@ISA=qw(Wheel); 
sub outerradius
{
 
  my ($c)   =@_; 
  if ($c->{r1}<$c->{r2})
  {
    return $c->{r2}; 
  }
  else
  {
    return $c->{r1}; 
  }
}
sub innerradius
{
  my ($c)=@_; 
  if ($c->{r1}<$c->{r2})
  {
    return $c->{r1}; 
  }
  else
  {
    return $c->{r2}; 
  }
}

# ring 
# cal as either   t,$cuttersize,$passes,$passdepth,$r1,$r2,$z   (pld style) 
# or hash containing 
sub new
{
    my ($t,$cuttersize,$passes,$passdepth,$r1,$r2,$z)=@_; # die "$s , $n,".ref($n);

    my $s={};

    my $h=$cuttersize; # might be has or cuttersize at this stage, we dont know. 

    if (ref($h) eq 'HASH')  #  means we've been passed a hash ref
    { 
       for my $key (qw(cuttersize passdepth r1 r2 z holesize holedepth holepassdepth)) 
       { 
          $h->{$key}=Wheel::dim(undef,$h->{$key}); 
       } 
       for my $key (qw(cuttersize passes passdepth r1 r2 z holesize holedepth holepasses holepassdepth)) 
       { 
          $s->{$key}=$h->{$key}; 
       } 

       # if holesize is defined, there willl be a hole at the center. 
       # need to get holepasses and holepassdepth which we actually use. 
       
       if (!defined($s->{holedepth})) #  and !defined($s->{holepasses} and !defined($s->{holepassdepth})
       {
          $s->{holepassdepth}||=$s->{passdepth}; 
          $s->{holepasses}||=$s->{passes}; 
       }
       elsif (defined($s->{holedepth}) and !defined($s->{holepasses}))  # holepassdepth def or undef 
       {
          
          $s->{holepassdepth}||=$s->{passdepth};    # provisional. 
          $s->{holepasses}=abs($s->{holedepth}/$s->{holepassdepth}); 
          $s->{holepasses}=int($s->{holepasses})+1 if ($s->{holepasses}!=int($s->{holepasses})); 
          $s->{holepassdepth}=-abs($s->{holedepth})/$s->{holepasses};  
       }
       elsif (defined($s->{holedepth}) and defined($s->{holepasses})) # ignore passdepth even if provided.  and !defined($s->{holepassdepth})
       {
          $s->{holepassdepth}=-abs($s->{holedepth})/$s->{holepasses}; 
       }
       
       if ($s->{holesize})
       { 
         my $hole=Hole->new($s->{cuttersize},$s->{holepasses},$s->{holepassdepth},$s->{holesize}); 
         $s->{hole}=$hole; 
         map { delete $s->{$_} } qw( holesize holedepth holepasses holepassdepth ); 
       }
 
    }
    else
    {
      $s->{cuttersize}=Wheel::dim(undef,$cuttersize); 
      $s->{passes}=$passes; 
      $s->{passdepth}=Wheel::dim(undef,$passdepth); 
      $s->{r1}=Wheel::dim(undef,$r1); 
      $s->{r2}=Wheel::dim(undef,$r2); 
      print "ring new r1 is $r1 r2 is $r2\n"; 
      $s->{z}=$z if (defined($z));; 
    }
    $s= bless $s,$t;
    print "new ring s is $s\n";      
    return $s; 
}
# ring 
sub widen
{
  my ($s,$r)=@_;

  if ($s->{r2}>$s->{r1} and $s->{r2}<$r)
  {
    $s->{r2}=$r; 
  }
  elsif ($s->{r1}>$s->{r2} and $s->{r1}<$r)
  {
    $s->{r1}=$r; 
  }
  return $r; 
}
sub setr2
{
  my ($s,$r)=@_;
  print "r2 on $s->{name} changed from $s->{r2} to  $r\n"; 
  $s->{r2}=$r; 
  return $r; 
}
sub setr1
{
  my ($s,$r)=@_;
  print "r2 on $s->{name} changed from $s->{r1} to  $r\n"; 
  $s->{r1}=$r; 
  return $r; 
}
# ring 
sub cut
# The purose of this function is to create an integral boss, and face off the material underneath os that the teeth can be cut. 
# Youll need a thick piece of material to use this as the material has to be thick enough both for the boss and the wheel. 
# Its appropriate particularly for pinions. 
# face off a circular area in steps of a half cutter radius
{                   
  my ($c,$g,$x,$y,$z)=@_; 
  # variables are 
  # ring object 
  # (graphics object), 
  # where to center(x,y), 
  # where to start in z plane, often z=0 is appropriate 
  # what cut to take in z plane on each pass, normally negative
  # how many passes, 
  # final radius, 
  # initial radius, make bigger than final radius to start outside. 
  # cuttersize (diameter) and 
  # units are all inches. 


printf "calling cut on a %s name is %s r1 is %f r2 is %f\n",ref($c),$c->{name},$c->{r1},$c->{r2}; 

  $g->grapid('z',0.1);

  my $dd=abs($c->{r1}- $c->{r2});                 
  die "Anulus too narrow for toolsize r1 is $c->{r1} r2 is $c->{r2} \nanulus size is $dd toolsize is $c->{cuttersize}" 
                                                                    if (abs($c->{r2}-$c->{r1})<$c->{cuttersize}); 
  die "Need to have a cuttersize" if ($c->{cuttersize}<=0); 

  my $step; 
  my ($r1,$r2);
  $r1=$c->{r1}; 
  $r2=$c->{r2}; 
  if ($c->{r1}<$c->{r2})
  {
    $r2=$r2-$c->{cuttersize}/2;     # calculate compensated radii, compensated for tool radius. 
    $r1=$c->{r1}+$c->{cuttersize}/2; 
    $step=$c->{cuttersize}/2; 
  }
  else
  {
    $r2=$r2+$c->{cuttersize}/2;     # calculate compensated radii, compensated for tool radius. 
    $r1=$c->{r1}-$c->{cuttersize}/2; 
    $step= -$c->{cuttersize}/2; 
  }      
 
  $g->gcomment("cutting hole"); 
  $c->{hole}->cut($g,$x,$y,$z) if ($c->{hole}); 
  $g->gcomment("hole done"); 

  my $pass=0; 
  while ($pass++<$c->{passes})
  {                          
    $z+=$c->{passdepth};
    $g->gcomment("Cutting Anulus $pass of $c->{passes}"); 
#    $g->gmove('x',$x,'y',$y,'z',$z,'f',$feed);
    my $r=$r1-$step; # compensate for re-increment in 1st pass.       
    while (($r+$step<$r2)==($r<$r2))
    {      
      $r+=$step; 
      $g->gcomment("Radius is $r "); 
      $g->gmove('x',$x+$r,'y',$y,'f',$g->{feed}); 
      $g->gmove('z',$z); 
      $g->garccw('x',$x-$r,'y',$y,'r',$r); 
      $g->garccw('x',$x+$r,'y',$y,'r',$r); 
    }
   
    my $laststep=$r2-$r; 
    if ($laststep>0)
    {      
      $r+=$laststep; 
      $g->gcomment("Final radius is $r"); 
      $g->gmove('x',$x+$r,'y',$y,'f',$g->{feed});
      $g->gmove('z',$z); 
      $g->garccw('x',$x-$r,'y',$y,'r',$r); 
      $g->garccw('x',$x+$r,'y',$y,'r',$r); 
    }
  }
  $g->grapid('z',0.1);   
}

package Boss;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.061;  

	
sub new 
{
    my ($t,$cuttersize,$passes,$passdepth,$radius)=@_; 
    my $b={}; 
    print "boss new $radius, $cuttersize\n"; 
    $b->{ring}=Ring::new($t,$cuttersize,$passes,$passdepth,$radius,$radius+$cuttersize);
    return bless $b,$t; 
}
sub passes
{
 my ($b)=@_; 
 return $b->{ring}->{passes}; 
}
sub passdepth
{
 my ($b)=@_; 
 return $b->{ring}->{passdepth}; 
}
# boss
sub outerradius
{
  my ($b)=@_; 

  return $b->{ring}->{r2}>$b->{ring}->{r1}?$b->{ring}->{r1}:$b->{ring}->{r2}; # size of remaining metal. 
} 
sub innerradius
{
  my ($b)=@_; 
  return $b->{ring}->{r2}>$b->{ring}->{r1}?$b->{ring}->{r1}:$b->{ring}->{r2}; # size of remaining metal. 
} 
# boss
sub cut
{
  my ($b,$g,$x,$y,$z)=@_; 
    
  $b->{ring}->cut($g,$x,$y,$z) if ($b->{ring}); 
}

package Hole;
use vars qw($VERSION @ISA @EXPORT);
$VERSION=0.05;  

@ISA=('Ring'); 
sub new
{
    my ($t,$cuttersize,$passes,$passdepth,$diameter)=@_; 
#    return bless SUPER::new($t,$cuttersize,$passes,$passdepth,$bosssize,0),$t;
    return bless Ring::new($t,$cuttersize,$passes,$passdepth,$diameter/2,0),$t;
}

1;          
__END__


=head1 NAME

cog - Perl extension for cutting cycloidal gear wheels and related items out of 
      sheet metal

=head1 SYNOPSIS

  use CNC::Cog;
  use CNC::Cog::Gdcode;                  
  use CNC::Cog::Gcode; 

Of the last two modules above, only one is strictly speaking necessary at a time.
They provide the output functionality for the cog module. If you use gdcode,
then you will also need the perl module GD, which produces a .png file 
of the output instead of the G-code. 

  $c=newcogpair cog(3.0,7,18);      # make a pinion and a wheel module 3, 
                                    # with 7 and 18 teeth respectively.

This generates two wheel objects, pinion and wheel, which are closely based
on the british standard for cycloidal gear wheels. 

  $c->cutset({cuttersize=>0.125,passes=>3,passdepth=> -0.025 }); 

This sets up some information about the cutter to be used. Things like

  $c->{wheel}->{cuttersize}=0.125

have a similar effect. 

The function can also be called as 

  $c->cutset(0.125,3,-0.025); # cuttersize, passes, passdepth

or as

  $c->{wheel}->cutset(....);

Note that the passdepth should always be negative. These dimentions are in
inches, as are nearly all dimentions here, except for module which has 
dimentions of mm. This is a bit incongrous and needs to be fixed. 

  $c->{wheel}->hole(0.125); 
  $c->{pinion}->hole(0.25);  

Produces holes of the appropriate size (diameter) in the center of the wheel. 
The hole size can be any size greater than or equal to the cutter size. 

  my $feed=3; 
  my $g=new Gcode("test.ngc",$feed,5);    

This produces a graphics object that generates G-code in the file specified. 
The feed rate will be as specified, and the cuttercompensation will be based 
on (in this case) tool number 5. You need to ensure that this has the same
diameter as specified in thgis code in your tool table, as otherwise the 
cutter compensation where used will give incorrect results. 

  my $g=new Gdcode("test.png",4.50 ,400,400);

This is an alternative line to the line above, and produces a similar object
with the same interface, that produces a png file. It is a square file scaled
4.5 inches in the y direction and of size 400 x 400 pixels. in the 
example given. Note that you can increase the resolution by increasing this 
number but if you make it too big, as the lines are only ever 1 pixel wide some 
viewers may not show any lines unless you zoom in. However I often use pixel 
sizes between 1000 and 8000 to see the fine detail.


  $g->ginit();                # initialise the graphics object.                

  $c->{wheel}->cut($g,0,-0.75,0); # cut the wheel at this location x,y,z. 
  $c->{pinion}->cut($g,0,1.25,0); # cut the pinion here. 

  $g->gend();                 # finalise graphics operations, write files etc.                       


=head1 ABSTRACT
 
This package allows cutting of cog wheels from sheet metal that are 
tightly based on the british standard. It also allows a few other objects 
to be cut including a Graham style escapement, wheel bosses and holes. 
Objects can be stacked one on top of the other, cutting the combined object 
out of a solid block of metal. 


=head1 DESCRIPTION

The following classes are intended for top level use: 

  Cog - generates a meshing pair of toothed wheels. 
  Wheel - instance of a toothed wheel.  
  Boss        - Wheel center for physical attachment
  Ring        - represents a cylendrical space, possibly needing several
                passes both in depth and radius.  
  Hole        - class for a hole. 
  Stack       - cut one or more objects on top of each other
                with this special class
  Grahamwheel - wheel for Graham escapement
  Grahamyoke  - yoke/anchor for Graham escapement 

Each of these are described below. 

=head3 Cog

A Cog object has two components each of which is a Wheel. Therefore a cog object
is really a pair of Wheels. They are generated to mesh with each other 
and the shape of the teeth especially in the pinion is influenced by how many 
teeth each wheel has. 

The Wheels need to be individually cut. 

The following methods are available: 

newcogpair
cutset

=head4 newcogpair

Can be called in two ways, either with parameters as follows: 

   module    Module
   np 	     Number of teeth on the pinion. 
   nw        Number of teeth on the wheel. 

or it can be called with a hash reference with the following parameters: 

   module
   dpi       Diametrical Pitch, number of teeth per inch at the pitch diameter
             Note: module=1/(dpi*25.4) Either module or dpi should be used. 
   np 	     Number of teeth on the pinion. 
   nw        Number of teeth on the wheel. 

In both cases nw should be greater than or equal to np. 

It is necessary to call cut on the wheels in a cogpair seperately to ensure they
are plotted in seperate places. 

=head4 cutset

This function when called on a cog pair calls the function by the same name 
on each of the two component wheels. The parameters are as follows: 

  cuttersize   The size (diameter) of the cutter being used to cut the wheels
  passes       How many passes to make vertically. 
  passdepth    How deep to go on each pass. Should be a small negative number. 

  Alternatively a hash ref may be provided with some of the following keys: 

  cuttersize
  passes       *
  passdepth    *
  depth	       *
  holedepth

Descriptions are as above. Out of the parameters marked *, any two may be provided.
holedepth is a synonym for depth and does not designate that there is to be a hole. 

=head3 Wheel

This is the basic class for a cog wheel. Methods are as follows. 
Note that no code is produced until the cut function is called, and 
that the cut function can be called more than once at different locations. 

=head4 cutset

Sets up certain parameters. Identical to cog->cutset. See below. 

=head4 trepan

This refers to lightening  the wheel by cutting windows in it. A variety of
different window shapes may be cut, all of which result in some kind of 
spoked wheel. You might also achieve a similar effect by cutting holes, 
but I have not done this. Parameters are as follows: 

        spoken  Number of spokes
        wos     Total width of spokes in inches. Needs to be significantly
	            less 2pi * $br. 
        br,     Boss radius in absolute in inches, the solid bit at 
                center of wheel
        rt,     Rim thickness in inches. 
        roe,    Radius of window edge in inches, the curved radius of the
	            join between a spoke and the rim or boss
                Note: that this must be more than the cutter size or you 
		        cannot cut it! This is radius, not diameter. 
        wobf,   Width at base factor, > 1 for wider spoke base. 
	            Tapered spokes anyone ? 
        srf    Spoke rotation factor rotates spoke position this 
	            proportion of a full rotation on relative to outer rim.  
                Think rubber spokes! values 0 to 0.1 give good results. 

Not that not all values will allways work flawlessly, in particular if you make
the spokes so wide that they will not fit round the boss in the center of the
wheel, then this is not detected and will cause faulty output. 

The linear dimentions wos, br, rt, roe  may be given as
strings terminating in any of the following:

t  Take measurment in thousandths of an inch
p  Take measurment in seventy-twoths of an inch, points
mm Take measurement in milli-metres
i  Take measurement in inches, default. 

so any of the following would be valid as the second parameter of the trepan 
function and should give identical results. 

"12.7mm" , "0.5i" , "0.5" , 0.5 , "36p", "500t", "500.0t"

=head4 hole

Create a hole in the wheel. The hole is cut to the same depth as the wheel. 

Parameters are are as follows: 

       diam  Diameter of the hole in inches or other units.
 
=head4 bossindent

Cuts a circular indented area at the center of a wheel perhaps for helping 
with ataching some other part mechanically. 

  diam          Diameter. 
  passdepth     Depth of each cutting pass. 
  passes        Number of passes
  feed          Feed rate. Optional. If not provided, default will 
                be used. 

=head4 cut

Actually generates code or graphical output.  See below. 

=head3 Ring

This object has many of the attributes of a wheel, and but represents
ring-shaped space that is machined out. 

A ring has the following functions: 

 innerradius
 outerradius
 hole
 new

=head4 innerradius

returns inner radius in inches. 

=head4 outerradius 

returns outer radius in inches.

=head4 hole

See Wheel->hole()

=head4 new

May take either a hash reference, or the following parameters: 

    cuttersize	  Diameter of cutter being used
    passes        How many passes to make. 
    passdepth     Depth of each pass. 
    r1            Start radius
    r2            Final radius
    z             Depth at which to start cutting out the ring. 

In the case that a hash reference is provided, the following keys are recognised: 

    cuttersize    Diameter of cutter being used
    passes        How many passes to make.
    passdepth	  Depth of each pass.
    r1            Start radius
    r2            Final radius
    z		  Depth at which to start cutting out the ring.
    holesize	  Diameter of hole
    holedepth	  Depth of hole
    holepasses	  Number of passes for hole 
    holepassdepth Number of passes for the hole. Any 2 out of these last three only
                  need to be provided. 

Any linear dimention may be in non default units, see wheel-> trepan. 

r1 are the initial and final radii. r1 can be greater than r2 or vice versa, 
but the cutting will start at r1 and move in or out as appropriate towards r2. 

=head4 cut

Actually generates code or graphical output.  See below.

=head3 Stack

The stack class is used for cutting 2 or more objects at the same point on a 
piece of metal. It is assumed that they will be stacked in the order 
smallest on top and largest under neath, and that each object will have
an area that is not machined in the center so that the object above can be 
machined there. The stack function automatically machines out space surrounding 
smaller objects so that the way is clear to machine the larger objects underneath.

Methods are as follows: 

  new
  add
  insert
  cut

=head4 new

Creates a new stack object to which other objects may latter be added. 

Parameters are as follows: 

 cuttersize
 passes
 passdepth

These values are used as defaults or for new objects created as part of the
stacking process, not for the objects in the stack itself. 

=head4 add

Takes 1 or more objects and adds them into the stack. The objects should 
be in the order, the object nearest the top to be first. Add should 
be used only to add larger objects if it is used more than once. 


=head4 insert

like add, alo takes 1 or more objects and inserts them into the stack , except
that objects are inserted before all those that currently exist.  Smaller
objects should be inserted. They will be machined nearer the surface. 


=head4 cut

All the objects in the stack will be cut at the x and y co-ordinates
given, starting at the z co-ordinate given with further objects plotted
lower down to suit. 

Takes parameters x, y, z. 

=head3 Grahamwheel

This is subclassed from wheel and so all wheel methods apply. A Graham wheel
is defined as a a wheel with straight sided teeth, the sides being 
inline with a point offset from the wheel center so that the teeth slope. The
teeth may be narrower at the top than the bottem, and the relative amont of 
space on the wheel circumference given to the tooth and the intertooth gap 
may be controlled. The tooth is topped with a shape that may be chosen from 
a number of alternatives. 

=head4 new

The new function of the Grahamwheel class needs to passed a hash with some 
or all of the following parameters: 

  lift              If a flat tooth top is used then this parameter can be 
                    used to increase the height of the trailing edge of the
                    tooth top. 
  nteeth            How many teeth to have.
  externald         The external diameter of the wheel. 
  toothdepth        How deep the spaces between teeth should be.
  toothtop          Size in degrees of the top of the tooth. 
  toothtoppc        Alternatively, size as a percentage of 1 tooth-and-gap. 
  toothbase         Size in degrees of the tooth at the base
  toothbasepc       Alternatively, size as % of tooth-and-gap. 
  offset            In degrees of top of tooth from bottom. 
  holesize          If set, gives a hole at center of wheel. 
  topshape          Should be one of the following strings: 
                       flat       Gives a flat tooth top
                       circ       Similar to flat, but give a circular
                                  shape centered on the wheel center. As
                                  This is a large distance, this is nearly 
                                  flat. Flat may work better with the lift
                                  parameter set. 
                       bicirc     Two approx quarter circles are used with 
                                  a flat piece in between them 
                       circlead   The leading edge only is rounded. 
                       circtrail  The trailing edge only is rounded
                       semi       A (near) semi circle of the right diameter 
                                  is used. 
  toothradius       The radius used in bicirc, circlead and circtrail
  toothradiuspc     Alternative using percentage of tooth-and-gap
  filletradius      radius used at botto of tooth. Must be greater than cutter
                    radius. 
  

=head4 cut

The cut function takes an optional extra rotation parameter theta as well as
conventional x,y and z parameters. See below. 

=head3 Grahamyoke

=head4 new

New takes a has which may contain any of the following parameters:
Nearly all parameters may have l or r added to the end in case different 
parameters are required for left and right, otherwise both left and right
sides will be the same. This does not of course mean symetric since 
lift is always applied in such a way as to lift the yoke. 

Parameters that may have l and/or r applied are as follows: 

    lift 
    r 
    angle
    leradius
    droopangle

Parameters and their meanings are as follows: 

    lift        lift degrees (of pendulum swing)
                This is the angle that force would be applied to the pendulum
                if no rounding on wheel or yoke tooth edges is used. If these 
                are used then the angle of applied force will be greater. 
    r           Innerradius of yoke.   
    armwidth    This is the thickness of the non-tooth part of the yoke. 
    width       Thickness of the teeth. 
    innerradius Cosmetic - This is the radius of inner curves, except
                for the lower one. 
    outerradius Cosmetic - This is the radius of outer curves, except 
                for the upper one. 
    topradius   Cosmetic - radius of top curve
    botradius   Cosmetic - radius of bottom curve
    angle       This is the angle subtended by the tooth at the suspension 
                point. 
    holesize    Diameter of a hole (if any) place at the pivot point. 
    leradius    Leading edge radius, if any. (Otherwise, sharp) Trailing edge
                is always sharp. 
    droopangle  Angle that yoke top makes with horizontal. 

Quantities marked cosmetic are cosmetic only in the sense that they do not
affect opperation directly. The inner radii need to be bigger than the cutter
as otherwise cutting will not be possible. All of these as well as being 
specified in arbitrary units in the normal way, may also be specified
as percent in which case this is taken as percent of armwidth. For example

  "120%" 

Where angles are supplied, these can be supplied in radians by appending an r
to the value: 

"1.01r"

Such values are lift angle droopangle

As is normally the case, linear dimentions may have units appended and will 
be converted. These are 

r armwidth width innerradius outerradius botradius topradius holesize leradius

and l-r varients. 

=head4 Example Code For Graham

The Graham wheel and yoke are in a more experimental state than the rest of
the code. The code below is the code I used: 

  my $nteeth=40; 
  my $w=new Grahamwheel({
                nteeth=>$nteeth, 
                externald=>1.75,
                toothdepth=>0.1,
                offset=>2,      # degrees 
                toothbase=>30,  # percent of whole tooth gap. 
                toothtoppc=>8,   # percent of whole tooth gap, ie of 360/nteeth
                toothradiuspc=>50,
                lift=>0.00,  # inches
                filletradius=>0.033,    # radius used to cut tooth gap, in 
                               # inches, should be just greater than cutter. 
                holesize=>5/32, 
                topshape=>'semi'});


  my $sheetthickness=0.135; # Nominally an 1/8 inch sheet, Make slightly more
                            # to get a clean cut 
  $w->cutset(1/16,5,-$sheetthickness/5); # cuttersize, passes, passdepth
  
  $w->trepan(8,0.5,0.2,0.050,0.05,6.0,0.1);
  $w->bossindent(0.25,-0.015,1);  # diameter indent, depth indent, num passes

  my $cuty=0;  # set non zero, eg -0.9 to seperate parts for cutting. 
                                  
  $w->cut($g,0,$cuty-0.2,0,0); # cut the wheel. 

  my $pi=4.0 * atan2(1, 1);

  my $ns=8.75;  # how many teeth to span, more gives less swing 
  my $angle=16;  # working face angle, from center line.
  
  my $a=360*$ns/$nteeth/2; # angle between yolk tooth and vertical at wheel center

  # externald - toothdepth/2 from above   
  my $h=(1.75-0.1/2)/2/cos($a*$pi/180); # This is dist between centeres of 
                                        # yoke and wheel. Gives 90 deg line 
                                        # of action. 
  my $R=sqrt($h**2-(1.75/2)**2);        # length of arm

  my $droop=$a-$angle; # Droop angle. 
  my $ltg=2*$pi*(1.75-0.2)/2/40;        # linear tooth gap, used to get 
  print "ltg=$ltg\n";                   # size of yoke teeth about right

  $w=new Grahamyoke({ droopangle=>$droop,
                      leradius=>0.015,
                      angle=>$angle,
                      r=>$R,
                      width=>$ltg/4, 
                      lift=>1,
                      armwidth=>0.25, 
                      innerradius=>0.07, 
                      outerradius=>0.1,
                      topradius=>0.2,
                      botradius=>0.2,
                      holesize=>5/32,
                   });

  $w->cutset(1/16,5,-$sheetthickness/5); # cuttersize, passes, passdepth
  $w->cut($g,0,$cuty+$h-0.2,0,3); 

  $g->gend(); 

=head4 Comments On The Code

There is a lot of ugliness here. Many constants are added in and then
written in explicitly further down. I know this. Its clear that some further
encapsulation is needed. I've not done that yet because I've not yet 
finished testing my escapement. I include the code because its difficult
to see what I'm doing without it. Its a basis for you to experiment. 

=head3 Boss;

Cuts a cylendrical piece of metal with or without a hole at the center. 
Intended to be attached (in some way) to a wheel a grubscrew maybe 
enabling attachment to a shaft. 

Methods are as follows: 

  new
  cut

=head4 new

Parameters are

    cuttersize
    passes
    passdepth
    radius

=head4 cut

Actually generates code or graphical output.  See below. 

=head3 Hole

Methods are as follows: 
  
  new
  cut
  
=head4 new

    cuttersize      Cuttersize, less than or equal to hole diameter. 
    passes          Number of passes 
    passdepth       Depth of each pass
    diameter        Diameter of hole

=head4 cut

Actually generates code or graphical output.  See below. 


=head3 Profile

This is a convienence class used in cutting Grahamwheel and Grahamyoke. 
It effectively stores an array of points to cut and enables certain
operations like rotateion or translation on the pointset. As it turns out
its a much better way of generating parts and wheels than that used 
in parts written earlier. Well, you live and learn.  

Not required for use of high level functions. 

=head2 General methods                              

General methods for most classes are as follows.

cut
new (covered above.) 

=head4 cut

parameters are as follows: 

    x 	   Placement location x coordinate.
    y	   Placement location y coordinate
    z      Placement location z. You should normally set up the machine
           so that z=0 corresponds to the metal surface. z can be set to some
	   neagative quantity if some metal has already been machined away. 
    theta  Available only on Grahamwheel and Grahamyoke, adds an optional 
           rotation to the pieces. Used mainly in checking design of 
	   generated pieces before committing to metal. 

It is possible to call cut any number of times on an object, at a different
place in the x-y plane to cut out another instance of the object. 

=head4 new

Generate a new object. Parameters vary, see above. 

=head1 COMPATABILITY

G-code is a many headed serpent, and I cannot say what the compatability
with your version or machine will be. What I can say is that the code produced
uses only the most basic primatives: moves in straight lines and arcs, so 
that I expect it to be compatible with much. However, it is certainly
possible that your set up requires some different code or initialisation or
finalisation. I'd like to hear about this. 

The code has been tested on a Sherline table top CNC Mill, using EMC to drive
it, so the varient of G-code used is that understood by EMC. 

=head1 DISCLAIMER

Before you feed any G-code generated by this module to a machine tool you 
should satisfy yourself by whatever method, that it is safe to do so. Machine
tools can be dangerous if used improperly and nothing in this document 
should be taken as implying that this is not so. USE AT YOUR RISK!

=head1 KNOWN BUGS

When using Gdcode and GD, there appear to be inaccuracies in some 
of the arc functions. These show up as small disjoints in the lines near one
end of an arc. I have not been able to track this down. 

I have not got round to involute gears yet.  

Installation doesnt work correctly under Unix operating systems due to faults
in packaging and the packaging system that need a cleverer man than I to fathom. 

=head1 SEE ALSO

Some examples with photographs are here: 

http://www.jetmark.co.uk/cog

Its possible that this has grown since this package was posted on CPAN. If not
then the same documentation can be found installed with the perl source files.

The theoretical material for gearwheels (with the exception of the 
Graham classes) draws heavily on this reference: 

http://watchmaking.csparks.com/CycloidalGears/

The EMC home page is here: 

http://www.linuxcnc.org/

This defines the varient of G-code that I am using a subset of. 

=head1 AUTHOR

Mark Winder <mark.winder4@btinternet.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Winder

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

I would be intrested to hear from anbody who has comments or experiance
of its use. 

=cut



