package Tk::Scope;
use strict;
use Tk;
use Tk::widgets qw(Canvas Scrollbar DialogBox);
use Audio::Data;
use base qw(Tk::Derived Tk::Canvas);
use File::Temp qw(tempfile);

Construct Tk::Widget 'Scope';

sub ClassInit
{
 my ($class,$mw) = @_;
 
 $mw->bind($class,'<4>',[Wheel => -1, Ev('x')]); 
 $mw->bind($class,'<5>',[Wheel => 1, Ev('x')]); 
 
 $mw->bind($class,'<1>',[Cursor => 1,Ev('x')]); 
 $mw->bind($class,'<B1-Motion>',[Cursor => 2,Ev('x')]); 
 $mw->bind($class,'<ButtonRelease-1>',[Range => Ev('x'),-rangecmd => 1,2,Ev('s')]); 

 $mw->bind($class,'<3>',[Cursor => 'z1',Ev('x')]); 
 $mw->bind($class,'<B3-Motion>',[Cursor => 'z2',Ev('x')]); 
 $mw->bind($class,'<ButtonRelease-3>',[Range => Ev('x'),-zoomcmd => 'z1','z2',Ev('s')]); 
 
 $mw->bind($class,'<Configure>','scheduleRedisplay');
 $mw->bind($class,'<Print>','Print');
 return $class;
}
 
sub Wheel
{
 my ($c,$n,$x) = @_;
 $c->xview(scroll => $n*0.1, 'pages');
}

sub doZoom
{
 my ($c,$t1,$t2,$s) = @_; 
 # warn "Zoom '$s' $t1 -> $t2\n";
 if ($s =~ /Shift/)
  {
   my $s = $c->start;
   my $e = $c->end;
   my $w = $e-$s;               # width now
   my $dt = $t2-$t1;
   my $l1 = $w*$w/$dt;
   my $s1 = $s - ($t1-$s)*$w/$dt;
   $s1 = 0 if ($s1 < 0);
   my $e1 = $s1+$l1;
   $e1 = $c->xmax if ($e1 > $c->xmax);
   $c->start($s1); 
   $c->end($e1); 
  }
 else
  { 
   $c->start($t1); 
   $c->end($t2); 
  } 
}
 
sub Range
{
 my ($c,$x,$callback,$n,$m,@args) = @_;
 $m = 1 if ($m eq '2' && !$c->cget('-range1'));
 $c->Cursor($m,$x);
 unless($n =~ /^\d+$/)
  { 
   $c->itemconfigure($c->{"c$n"},-state => 'hidden');
   $c->itemconfigure($c->{"c$m"},-state => 'hidden');
  }  
 if (($n eq '1' && !$c->cget('-range1')) || ($c->{"cursor$n"} != $c->{"cursor$m"}))
  {
   my ($t1,$t2) = ($c->{"cursor$n"},$c->{"cursor$m"});
   ($t2,$t1) = ($t1,$t2) if $t1 > $t2;
   $c->Callback($callback => $t1,$t2,@args);
  } 
}

sub Cursor
{
 my ($c,$n,$x) = @_;
 $c->Tk::focus;
 $n = 1 if ($n eq '2' && !$c->cget('-range1'));
 if (@_ > 2)
  {
   $c->{"cursor$n"} = $c->x2val($x);
   $c->Callback(-command => "cursor$n");
  } 
 unless (exists $c->{"c$n"})
  {
   my @args;
   push(@args,-dash => '.') unless $n =~ /^\d+$/;
   $c->{"c$n"} = $c->create(line => [0,0,0,0],@args);
  }
 if ($c->{xmax} && defined $c->{"cursor$n"})
  { 
   $x   = $c->val2x($c->{"cursor$n"});  
   my $w = $c->Width;
   my $h = $c->Height;
   if ($x >= 0 && $x <= $w) 
    {
     $c->coords($c->{"c$n"},[$x,0,$x,$h]);
     $c->itemconfigure($c->{"c$n"},-state => 'normal');
    } 
   else
    {
     $c->itemconfigure($c->{"c$n"},-state => 'hidden');
    } 
  }
 else
  {
   $c->itemconfigure($c->{"c$n"},-state => 'hidden');
  }   
}

sub Populate
{
 my ($sc,$args) = @_;
 $sc->{trace} = {};  
 
 $sc->{xa} = $sc->create(line => [0,0,0,0]);
 $sc->{ya} = $sc->create(line => [0,0,0,0]);
	    
 $sc->ConfigSpecs(
		  -yscale => ['METHOD','yscale','Yscale',-1.0],  
		  -start  => ['METHOD','start','Start',0.0],  
		  -end    => ['METHOD','end','End',undef],  
		  -xmax    => ['METHOD','xmax','Xmax',undef],  
		  -access  => ['PASSIVE','access','Access','FETCH'],  
		  -command => ['CALLBACK','callback','Callback',undef],
		  -zoomcmd => ['CALLBACK','zoom','Zoom','doZoom'],
		  -rangecmd => ['CALLBACK','range','Range',undef],
                  -range1  => ['PASSIVE','range1','Range1','1'],
		  DEFAULT => [$sc], 
                 );  
}

sub xscale
{
 my $sc = shift;
 my $t0 = $sc->{start} || 0;
 my $t1 = $sc->{end}   || 0;
 my $w  = $sc->Width;
 return ($t1-$t0)/$w;
}

sub x2val
{
 my ($sc,$x) = @_;
 return $sc->start + $x*$sc->xscale; 
}

sub val2x
{
 my ($sc,$t) = @_;
 return ($t-$sc->start)/$sc->xscale; 
}

sub scheduleRedisplay
{
 my ($sc,@args) = @_;
 unless ($sc->{redisplay})
  {
   $sc->{redisplay} = $sc->afterIdle([Redisplay => $sc, @args]);
  }
}

sub traces
{
 my $sc = shift;
 return keys %{$sc->{trace}}; 
}

sub trace
{
 my ($sc,%args) = @_;
 my $id;
 if (exists $args{-data})
  {
   my $data = delete $args{-data};
   $id = $sc->create('line',[0,0,0,0],%args);
   $sc->traceconfigure($id,-data => $data);
  }
 else
  {
   $id = $sc->create('line',[0,0,0,0],%args);
  } 
 return $id;
}

sub traceconfigure
{
 my ($sc,$id,%args) = @_;
 if (exists $args{-data})
  {
   my $data = delete $args{-data};
   $sc->{trace}{$id} = $data;
   $sc->scheduleRedisplay('data');
  } 
 $sc->itemconfigure($id,%args) if keys %args; 
}

sub tracecget
{
 my ($sc,$id,$key) = @_;
 return $sc->{trace}{$id} if $key eq '-data';
 return $sc->itemcget($id,$key); 
}

sub attrib
{
 my ($sc,$key,$val) = @_;
 if (@_ > 2)
  {
   # warn "$key = $val\n";
   $sc->{$key} = $val; 
   $sc->scheduleRedisplay($key);
  } 
 return $sc->{$key};
}

foreach my $meth (qw(yscale start end xmax cursor1 cursor2))
 {
  no strict 'refs';
  my $key = $meth;
  *$meth = sub { shift->attrib($key => @_) };
 }
 
sub audio
{
 my ($sc,$t1,$t2,@tr) = @_;
 (@tr) = keys %{$sc->{trace}} unless @tr;
 my @result;
 
 foreach my $tr (@tr)
  {
   my $data = $sc->{trace}{$tr}->timerange($t1,$t2);
   return $data unless wantarray;
   push @result,$data;
  }
 return @result; 
}

sub Redisplay
{
 my ($sc,$why) = @_;
 delete $sc->{redisplay};
 # warn "Redisplay $why\n";
 my $w  = $sc->Width;
 my $h   = $sc->Height/2;
 my $dur = $sc->{xmax};
 
 $sc->Callback(-xscrollcommand => $sc->start/$dur,$sc->end/$dur) if $dur;  
 
 foreach my $n (1,2)
  {
   $sc->Cursor($n) if exists $sc->{"cursor$n"};
  }
  
 foreach my $tr (keys %{$sc->{trace}})
  {
   my $ys = $sc->{yscale};
   my $data = $sc->{trace}{$tr};
   my $rate = $data->samples/$sc->{xmax};
   next unless $rate;
   my @coord;
   my $acc = $sc->cget('-access');
   my $ds = ($sc->x2val(1)-$sc->start)*$rate;
   my $yb = $h;
   if ($ds > 1)
    {
     # several samples in one pixel
     # warn "$ds = max/min\n"; 
     unless (defined $ys)
      {
       my ($max,$min) = $data->bounds($sc->x2val(0),$sc->x2val($w-1));
       $ys = ($max == $min) ? -1 : -2/($max-$min);  
       $yb = 2*$h-($min*$h*$ys);
      }
     for my $x (0..$w-1)
      {
       my $t  = $sc->x2val($x);
       my $t1 = $sc->x2val($x+1);
       my $samp = int($t*$rate);
       my ($max,$min);
       if ($acc eq 'FETCH')
        {
	 ($max,$min) = $data->bounds($t,$t1);
         $max = $max*$h*$ys+$yb;
         $min = $min*$h*$ys+$yb;
	}
       else 
        { 
         while ($t < $t1)
          {
           my $v = $data->$acc($samp);
           $v = 0 unless defined $v;
           my $y = $v*$h*$ys+$yb;
           $max = $y if (!defined($max) || $y > $max);
           $min = $y if (!defined($min) || $y < $min);
	   $samp++;
	   $t += 1/$rate;
  	  } 
	}  
       push(@coord,$x,$max,$x,$min);	
      }
     } 
    else
     {
      # several pixels in one sample
      # warn "$ds = lines\n"; 
      unless (defined $ys)
       {
        my ($max,$min);
        for (my $t = $sc->start; $t < $sc->end; $t += 1/$rate)
         {
          my $samp = int($t*$rate);
          my $v = $data->$acc($samp);
          $v = 0 unless defined $v;
          $max = $v if (!defined($max) || $v > $max);
          $min = $v if (!defined($min) || $v < $min);
	 }
	$ys = ($max == $min) ? -1 : -2/($max-$min);  
	$yb = 2*$h-($min*$h*$ys);
       }
      for (my $t = $sc->start; $t < $sc->end; $t += 1/$rate)
       {
        my $samp = int($t*$rate);
        my $v = $data->$acc($samp);
        $v = 0 unless defined $v;
        my $y = $v*$h*$ys+$yb;
	push(@coord,$sc->val2x($t),$y);
       } 
     } 
   $sc->coords($tr,\@coord); 
  }
 $sc->Callback(-command => $why);
}


sub scroll
{
 my ($sc,$am,$what) = @_;
 # warn "scroll $am $what\n";
 my $new = $sc->x2val($am*(($what eq 'pages') ? $sc->Width/2 : 1));
 $sc->moveto($new/$sc->xmax);
}

sub moveto
{
 my ($sc,$frac) = @_;
 # warn "moveto $frac\n";
 my $w = $sc->end - $sc->start;
 my $s = $sc->xmax*$frac;
 my $e = $s+$w;
 if ($e > $sc->xmax)
  {
   $e = $sc->xmax;
   $s = $e-$w;
  }
 if ($s < 0)
  {
   $s = 0; 
   $e = $s+$w; 
  }
 $sc->start($s);
 $sc->end($e);
}

sub xview
{
 my ($sc,$cmd,@args) = @_;
 $sc->$cmd(@args);
}

my %page_sizes;

sub page_sizes
{
 unless (keys %page_sizes)
  {
   my @list;
   my ($w,$h) = (297,420);
   for my $size (3..5)
    {
     $page_sizes{"A$size"} = [$w,$h];
     ($h,$w) = ($w,$h/2);
    }
  }
 return \%page_sizes;
}

sub printers
{
 my @list;
 if (open(my $fh,"/etc/printcap"))
  {
   while (<$fh>)
    {
     s/^\s+//;
     s/#.*$//;
     push(@list,$1) if (/^(\w+)/);
    }
   close($fh);
  }
 else
  {
   warn "Cannot open /etc/printcap:$!";
  }
 return @list;
}



sub Print
{
 my ($c) = @_;
 my $d = $c->DialogBox(-buttons => [qw(Ok Cancel)],
                       -title => 'Print Options',
		       -popover => 'cursor', -popanchor => 'nw');
 my $ps = page_sizes();
 my $psize = 'A4';
 my $mode = 'color';
 my $path = 'plot.ps';
 my $what = 'All';
 my $printer = 'File';
 my @lopts = (-anchor => 'e', -justify => 'right');
 Tk::grid(
          $d->add('Label',-text => 'Print:',@lopts),
#         $d->add('Optionmenu', -variable => \$what, -options => ['Window','All']),
          $d->add('Label',-text => 'Paper Size:',@lopts),
          $d->add('Optionmenu', -variable => \$psize, -options => [sort keys %$ps]),
          -sticky => 'nsew'
         );
 Tk::grid(
          $d->add('Label',-text => 'Colour mode:',,@lopts),
          $d->add('Optionmenu', -variable => \$mode, -options => [qw(color gray mono)]),
          $d->add('Label',-text => 'Printer:',@lopts),
          $d->add('Optionmenu', -variable => \$printer, -options => [File => printers()]),
          -sticky => 'nsew'
         );
 Tk::grid($d->add('Label',-text => 'File Name:',@lopts),
          $d->add('Entry', -textvariable => \$path, -width => 30),'-',
          $d->add('Button', -text => 'Browse ...',
           -command => sub { $path = $d->getSaveFile(
	                      -initialfile => $path,
			      -initialdir => getcwd(),
                              -filetypes => [
                                ['PostScript Files' => ['.ps']],
                                ['All Files', '*']
                                ])
		     }
		),
         -sticky => 'nsew'
         );

 my $dst;
 do
  {
   my $opt = $d->Show();
   return if $opt eq 'Cancel';
   if ($printer eq 'File')
    {
     unless (length($path) && open($dst,">$path"))
      {
       $c->messagebox(-text => "Cannot open $path:$!");
      }
    }
   else
    {
     ($dst,$path) = tempfile();
    }
  } until (defined($dst) && fileno($dst));

 my %opt = (-colormode  => $mode);

 if ($what eq 'All')
  {
   @opt{'-x','-y','-width','-height'} = $c->bbox('all');
  }
 else
  {
   @opt{'-x','-y','-width','-height'} = ($c->canvasx(0), $c->canvasy(0),
                                         $c->canvasx($c->width), $c->canvasy($c->height));
  }
 $opt{'-width'}  -= $opt{'-x'};
 $opt{'-height'} -= $opt{'-y'};

 # PS origin is normally SW so avoid deltaX, deltaY
 $opt{'-pageanchor'} = 'sw';

 # Get raw page size - we are working in mm
 my ($pw,$ph) = @{$ps->{$psize}};

 # Allow a margin on each edge
 my $margin = 25.4*0.25;  # 1/4 inch on each edge

 $pw -= 2*$margin;
 $ph -= 2*$margin;
 $opt{-pagey}  = $margin;
 $opt{-pagey}  = $margin;

 # Decide if it fits better rotated
 $opt{'-rotate'} = ($opt{'-width'} > $opt{'-height'}) ? 1 : 0;
 if ($opt{-rotate})
  {
   # x is bigger so rotate, pw/ph are swapped
   ($pw,$ph) = ($ph,$pw);
   # and we have to shift it right to allow for rotate as ->postscript
   # method does not take that into account the scaled image will be at
   # most the "height" of the paper
   $opt{-pagex} += $ph;
  }

 # Now compute scale. pw/ph correspond to x/y size of space
 my $xs = $pw / $opt{-width};
 my $ys = $ph / $opt{-height};
 # Core tk prefers -pagewidth to -pageheight if both specified
 # So only add the one which corresponds to smallest scale so
 # that whole image fits
 if ($xs < $ys)
  {
   $opt{-pagewidth} = $pw;
  }
 else
  {
   $opt{-pageheight} = $ph;
  }
 # Now we have finished doing calculations append unit marker for core tk.
 foreach my $key (qw(-pagewidth -pageheight -pagex -pagey))
  {
   $opt{$key} .= 'm' if exists $opt{$key};
  }
# use Data::Dumper;
# warn Dumper(\%opt);
# pseudo_code($c,%opt);
 my ($fh,$temp) = tempfile();
 $c->postscript(-file => $temp, %opt);

 # Now edit PostScript to get thin lines
 # 1 pixel at 300dpi is 72/300 points
 my $t = 72/300;
 while (<$fh>)
  {
   if (/^(\s*(\d+(\.\d+))){2}\s+scale/)
    {
     warn "scale $2\n";
     $t /= $2;
    }
   else
    {
     s/^(\s*)(\d+)(\s+)setlinewidth/"$1".$t*$2."$3setlinewidth"/e;
    }
   print $dst $_;
  }
 close($fh);
 close($dst);
 unlink($temp);

 if ($printer ne 'File')
  {
   system(lpr => "-P$printer",$path);
   unlink($path);
  }
}


1;
__END__
