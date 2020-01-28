package Chart::Colors;

use strict;
use warnings;

# perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/Chart/Colors.pm  > README.md

=head1 NAME

Chart::Colors - Perl extension to return an endless stream of new distinct RGB colours codes (good for coloring any number of chart lines)

=head1 SYNOPSIS


    #!/usr/bin/perl -w
      
    use Chart::Colors;

    my $colors = new Chart::Colors();
    my $nextcolor_hex=$colors->Next('hex');	# Get an HTML-Style answer, like F85099 (put a # in front to use in HTML, i.e. #F85099)
    my($r,$g,$b)=$colors->Next('rgb');		# Get red, green, and blue ints separately, like (255,123,88)
    my($h,$s,$v)=$colors->Next('hsv');		# Get hue, saturation, and brightness


=head1 DESCRIPTION

This module outputs an infinte sequence of visually distinct different colours.

It is useful for colorizing the lines on charts etc.

=head2 EXAMPLE

	# perl -MChart::Colors -e '$c=new Chart::Colors(); for(my $i=0;$i<5;$i++) { print "$i\t( " . join(", ",$c->Next()) . " )\n";}; print "#" . $c->Next("hex") . "\n"; print join("|", $c->Next("hsv")) . "\n"; ' 
	0       ( 204, 81, 81 )
	1       ( 127, 51, 51 )
	2       ( 81, 204, 204 )
	3       ( 51, 127, 127 )
	4       ( 142, 204, 81 )
	#597f33
	0.75|0.6|0.8

=head2 EXPORT

None by default.


=head2 Notes

=head2 new

Usage is

    my $colors = new Chart::Colors();


=head2 Next

Returns a colour code in hexadecimal ('hex'), red, green, blue ('rgb') or hue, saturation, and brightnes ('hsv') format.

Usage is

    my $nextcolor_hex = $colors->Next('hex');

or

    my($r,$g,$b)=$colors->Next('rgb');

or

    my($h,$s,$v)=$colors->Next('hsv');	


=head2 hsv_to_rgb

    my($r,$g,$b)=$this->hsv_to_rgb($h,$s,$v);

=cut

require Exporter;

our @ISA = qw(Exporter);
our($VERSION)='1.03';
our($UntarError) = '';

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


sub new {
  my $class = shift;
  my $this={};
  $this->{rgbno}=0;
  @{$this->{rgbf}}=(0.8,0.5);
  $this->{base}=1;
  $this->{num}=1;
  $this->{ff}=undef;
  bless $this,$class;
  return $this;
} # new



sub Next {
  my $this = shift;
  my $type = shift; # 'hex' or 'rgb' or 'hsv'
  $type='' unless($type);

  $this->{ff}=$this->nextfrac() unless($this->{rgbno}%2);
  my($h,$s,$v)=($this->{ff},.6,$this->{rgbf}->[$this->{rgbno}++%2]);
  return ($h,$s,$v) if($type eq 'hsv');
  #return($this->hsv_to_rgb($ff,.6,$this->{rgbf[$this->{rgbno}++%2]}));	# RGB
  my($r,$g,$b)=$this->hsv_to_rgb($h,$s,$v); 
  return sprintf("%02x%02x%02x",$r,$g,$b) if($type eq 'hex');
  return($r,$g,$b) if($type eq 'rgb');
  return($r,$g,$b); # default to RGB
  #return($this->hsv_to_rgb($h,$s,$v)) if($type eq 'rgb');	# RGB
} # Next
# testing Next: perl -MChart::Colors -e '$c=new Chart::Colors(); for(my $i=0;$i<5;$i++) { print "$i\t( " . join(", ",$c->Next()) . " )\n"; }'  # correct= ['204,81,81', '127,51,51', '81,204,204', '51,127,127', '142,204,81']

sub nextfrac {	# Keep slicing between previous 0..1 range.
  my $this = shift;
  my $ret=($this->{base}==1)? 0: $this->{num}/$this->{base};
  $this->{num}+=2; 
  if($this->{num}>$this->{base}) {
    $this->{base}=2*$this->{base};
    $this->{num}=1;
  }
  return $ret;
} # nextfrac
# testing nextfrac: for(my $i=0;$i<20;$i++) { print "$i\t" . &nextfrac() . "\n"; } # correct= [0.0, 0.5, 0.25, 0.75, 0.125, 0.375, 0.625, 0.875, 0.0625, 0.1875, ...]

sub hsv_to_rgb {
  my $this = shift;
  my($h,$s,$v)=@_;		# All numbers range from 0..1
  #print "h=$h s=$s v=$v\n";
  return(0,0,0) if(!$s);	# Black is black
  my $i = int($h*6);
  my $f = $h*6-$i;
  my $p = int(255*($v*(1-$s)));
  my $q = int(255*($v*(1-$s*$f)));
  my $t = int(255*($v*(1-$s*(1-$f))));
  $v=int($v*255); 
  $i%=6;
  return ($v, $t, $p) if($i == 0);
  return ($q, $v, $p) if($i == 1);
  return ($p, $v, $t) if($i == 2);
  return ($p, $q, $v) if($i == 3);
  return ($t, $p, $v) if($i == 4);
  return ($v, $p, $q); # if($i == 5) 
} # hsv_to_rgb
# testing hsv_to_rgb: my $x; while( $x++<20){ my($h,$s,$v)=(rand(),rand(),rand()); print "($h,$s,$v)=(" . join(",",&hsv_to_rgb($h,$s,$v)) . ")\n"; };

#my $toprint=$ARGV[0]; $toprint++ unless($toprint); my @ret;push @ret,"'" . join(",",&Next()) . "'" while($toprint--); print "[". join(", ",@ret) . "]\n";


1;

__END__

=head1 AUTHOR

This module was written by Chris Drake F<cdrake@cpan.org>, and based on https://stackoverflow.com/questions/24852345/hsv-to-rgb-color-conversion


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut



=for original 

    # from https://stackoverflow.com/questions/24852345/hsv-to-rgb-color-conversion
    def hsv_to_rgb(h, s, v):
        if s == 0.0: v*=255; return (v, v, v)
        i = int(h*6.) # XXX assume int() truncates!
        f = (h*6.)-i; p,q,t = int(255*(v*(1.-s))), int(255*(v*(1.-s*f))), int(255*(v*(1.-s*(1.-f)))); v*=255; i%=6
        if i == 0: return (v, t, p)
        if i == 1: return (q, v, p)
        if i == 2: return (p, v, t)
        if i == 3: return (p, q, v)
        if i == 4: return (t, p, v)
        if i == 5: return (v, p, q)

=cut



=for code_copied

# !/usr/bin/env python3.3

from sys import argv
import colorsys
import itertools
from fractions import Fraction

def zenos_dichotomy():
    for k in itertools.count():
        yield Fraction(1,2**k)	# yeild is like return, except next call continues

def getfracs():
    """
    [Fraction(0, 1), Fraction(1, 2), Fraction(1, 4), Fraction(3, 4), Fraction(1, 8), Fraction(3, 8), Fraction(5, 8), Fraction(7, 8), Fraction(1, 16), Fraction(3, 16), ...]
    [0.0, 0.5, 0.25, 0.75, 0.125, 0.375, 0.625, 0.875, 0.0625, 0.1875, ...]
    """
    yield 0
    for k in zenos_dichotomy():
        i = k.denominator # [1,2,4,8,16,...]
        for j in range(1,i,2):	# start,stop,step
            yield Fraction(j,i)

bias = lambda x: (math.sqrt(x/3)/Fraction(2,3)+Fraction(1,3))/Fraction(6,5) # can be used for the v in hsv to map linear values 0..1 to something that looks equidistant

def genhsv(h):
    for s in [Fraction(6,10)]: # optionally use range
        for v in [Fraction(8,10),Fraction(5,10)]: # could use range too
            yield (h, s, v) # use bias for v here if you use range

genrgb = lambda x: colorsys.hsv_to_rgb(*x)

flatten = itertools.chain.from_iterable

gethsvs = lambda: flatten(map(genhsv,getfracs()))

getrgbs = lambda: map(genrgb, gethsvs())

def genhtml(x):
    uint8tuple = map(lambda y: int(y*255), x)
    return "{},{},{}".format(*uint8tuple)

gethtmlcolors = lambda: map(genhtml, getrgbs())

if __name__ == "__main__":
    print(list(itertools.islice(gethtmlcolors(), int(argv[1]))))

#    print(list(itertools.islice(gethtmlcolors(), int(argv[1]))))
#    print(list(itertools.islice(gethtmlcolors(), 10)))

=cut

