#!/usr/bin/perl

use strict;

use Convert::Color;
use Getopt::Long;

print <<EOF;
<html>
 <body>
  <table border=1>
   <tr><th colspan=2>Name</th><th>RGB</th><th>HSL</th><th>CMYK</th></tr>
EOF

my @COL;

sub span
{
   my ( $text, $col ) = @_;

   my $hex = $col->as_rgb8->hex;

   if( $col->as_hsl->lightness < 0.5 ) {   
      return qq{<span style="background-color: #$hex; color: white">$text</span>};
   }
   else {
      return qq{<span style="background-color: #$hex">$text</span>};
   }
}

my $SORT = 0;

GetOptions(
   's|sort+' => \$SORT,
) or exit(1);

while( my $colname = shift @ARGV ) {
   if( $colname eq "x11:*" ) {
      require Convert::Color::X11;
      unshift @ARGV, map { "x11:$_" } sort Convert::Color::X11->colors;
      next;
   }

   my $col = Convert::Color->new( $colname );

   my $c_rgb8 = $col->as_rgb8;
   my $rgb8_hex = $c_rgb8->hex;

   my ( $r, $g, $b ) = $c_rgb8->rgb8;
   my $rgb = join ",",
      span( sprintf('%03d',$r), Convert::Color::RGB8->new( $r, 0, 0 ) ),
      span( sprintf('%03d',$g), Convert::Color::RGB8->new( 0, $g, 0 ) ),
      span( sprintf('%03d',$b), Convert::Color::RGB8->new( 0, 0, $b ) );

   my $c_hsl = $col->as_hsl;
   my ( $hue, $sat, $lig ) = $c_hsl->hsl;
   my $hsl = join ",",
      ( $sat <= 0.0001 ?
         span( "---", Convert::Color::HSL->new( 0, 0, 0.5 ) ) :
         span( sprintf('%.1f',$hue), Convert::Color::HSL->new( $hue, 1, 0.5 ) ) ),
      span( sprintf('%0.3f',$sat), Convert::Color::HSL->new( $hue, $sat, 0.5 ) ),
      span( sprintf('%0.3f',$lig), Convert::Color::HSL->new( 0, 0, $lig ) );

   my $c_cmyk = $col->as_cmyk;
   my ( $c, $m, $y, $k ) = $c_cmyk->cmyk;
   my $cmyk = join ",",
      span( sprintf('%0.3f',$c), Convert::Color::CMY->new( $c, 0, 0 ) ),
      span( sprintf('%0.3f',$m), Convert::Color::CMY->new( 0, $m, 0 ) ),
      span( sprintf('%0.3f',$y), Convert::Color::CMY->new( 0, 0, $y ) ),
      span( sprintf('%0.3f',$k), Convert::Color::CMYK->new( 0, 0, 0, $k ) );

   push @COL, [ ( $sat <= 0.0001 ? $lig - 2 : $hue ),
      <<"EOF" ];
    <tr><td>$colname</td><td bgcolor="#$rgb8_hex">&nbsp;&nbsp;&nbsp;</td><td>$rgb</td><td>$hsl</td><td>$cmyk</td></tr>
EOF

}

if( $SORT ) {
   @COL = sort { $a->[0] <=> $b->[0] } @COL;
}

print map { $_->[1] } @COL;

print <<EOF;
  </table>
 </body>
</html>
EOF
