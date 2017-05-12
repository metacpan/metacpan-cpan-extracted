package Color::Mix;

use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

sub new {
    my ($class) = shift;
    my $self = {}; 
    bless $self, ref($class) || $class;
    $self->_initialize;
    return $self;
}

##################################
#  P U B L I C    M E T H O D S
##################################

sub analogous {
    my ($self, $color, $my_slices, $slices) = @_;
    $my_slices ||= 3;
    $slices    ||= 12;
    $color = $self->get_color($color);
    my $angle = 360 / $slices;
    return $color, map { $self->_rotate($color, $angle*$_) } 1 .. $my_slices;
}


sub complementary {
    my ($self, $color) = @_;
    return $self->_rotate($color, 180);
}


sub double_complementary {
    my ($self, $primary, $secondary) = @_;
    return ($self->complementary($primary), $self->complementary($secondary));
}


sub trinary {
    my ($self, $primary) = @_;
    return ($self->get_color($primary), $self->_rotate($primary, 120), $self->_rotate($primary, 240)); 
}


sub lighten {
    my ($self, $color, $by) = @_;
    $color = $self->get_color($color);
    $by||=1;
    my $shade = $self->get_shade;
    return sprintf('%.2x%.2x%.2x', map { ( $_ + $shade * $by > 255) ? 255 : $_ + $shade * $by  } 
        $self->_rgb($color));
}


sub darken {
    my ($self, $color, $by) = @_;
    $color = $self->get_color($color);
    $by||=1;
    my $shade = $self->get_shade;
    return sprintf('%.2x%.2x%.2x', map { ($_ - $shade * $by < 0) ? 0 : $_ - $shade * $by } 
        $self->_rgb($color));
}


sub get_color {
    my ($self, $color) = @_;
    return $color if $self->_is_hex_color($color);
    return $self->_get_named_color($color) if $self->_is_color_name($color);
    carp "Doesn't look like a valid color";
}


sub get_color_list {
    my ($self) = @_;
    return sort keys %{$self->{colors}};
}


sub set_shade {
    my ($self, $shade) = @_;
    $self->{shade_offset} = $shade;
}


sub get_shade {
    my ($self) = @_;
    return $self->{shade_offset};
}


##################################
#  P R I V A T E    M E T H O D S
##################################

sub _initialize {
    my ($self) = @_;
    $self->_setup_colors;
    $self->set_shade(32);
    return $self;
}

sub _rotate {
    my ($self, $color, $angle) = @_;
    my $hsv = $self->_RGB2HSV($color);
    $hsv->{hue} = $self->_shift_hue($hsv->{hue}, $angle);
    my $rotated = $self->_HSV2RGB($hsv);
    return sprintf("%.2x%.2x%.2x", $rotated->{r}, $rotated->{g}, $rotated->{b});
}


sub _minmax {
    my($self, @params) = @_;
    my $initial = shift @params;
    my $max = $initial;
    my $min = $initial;
    for (@params) {
        $max = $_ if $_ > $max;
        $min = $_ if $_ < $min;
    }
    return ($min,$max);
}


sub _is_hex_color {
    my ($self, $color) = @_;
    return 0 unless ($color =~ /^[0-9A-Fa-f]{6}$/);
    return 1;
}


sub _is_color_name {
    my ($self, $color) = @_;
    return 0 unless $self->_get_named_color($color);
    return 1;
}


sub _get_color_names {
    my ($self) = @_;
    return $self->{colors};
}


sub _RGB2HSV {
    my ($self, $hex) = @_;
    $hex = $self->get_color($hex);
    my %hsv;
    my ($r,$g,$b) = ($self->_rgb($hex)); 
    my ($min, $max) = $self->_minmax($r,$g,$b);
    my $dif = $max - $min;
    $hsv{saturation} = ($max == 0) ? 0 : (100*$dif / $max);
    if (!$hsv{saturation}) {
        $hsv{hue} = 0;
    }
    elsif ($r == $max) {
        $hsv{hue} = 60*($g - $b) / $dif;
    }
    elsif ($g == $max) {
        $hsv{hue} = 120+60*($b - $r) / $dif;
    }
    elsif ($b == $max) {
        $hsv{hue} = 240+60*($r - $g) / $dif;
    }
    $hsv{hue} += 360 if $hsv{hue} < 0;
    $hsv{value}      = sprintf("%.0f", $max*100 / 255);
    $hsv{hue}        = sprintf("%.0f", $hsv{hue});
    $hsv{saturation} = sprintf("%.0f", $hsv{saturation});
    $hsv{r} = $r;
    $hsv{g} = $g;
    $hsv{b} = $b;
    return \%hsv;
}


sub _HSV2RGB {
    my ($self, $hsv) =  @_;
    my ($r,$g,$b,$i,$f,$p,$q,$t,$rgb);
    if ($hsv->{saturation} eq "0") {
        $r = sprintf("%.0f",$hsv->{value} * 2.55);
        $g = sprintf("%.0f",$hsv->{value} * 2.55);
        $b = sprintf("%.0f",$hsv->{value} * 2.55);
    }
    else {
        $hsv->{hue} /= 60;
        $hsv->{saturation} /= 100;
        $hsv->{value} /= 100;
        $i = int($hsv->{hue});
        $f = $hsv->{hue} - $i;
        $p = $hsv->{value}*(1-$hsv->{saturation});
        $q = $hsv->{value}*(1-$hsv->{saturation}*$f);
        $t = $hsv->{value}*(1-$hsv->{saturation}*(1-$f));

        if ($i == 0)    { $r = $hsv->{value}; $g = $t; $b = $p; }
        elsif ($i == 1) { $r = $q; $g = $hsv->{value}; $b = $p; } 
        elsif ($i == 2) { $r = $p; $g = $hsv->{value}; $b = $t; } 
        elsif ($i == 3) { $r = $p; $g = $q; $b = $hsv->{value}; } 
        elsif ($i == 4) { $r = $t; $g = $p; $b = $hsv->{value}; }
        else            { $r = $hsv->{value}; $g = $p; $b = $q; }

        $r = sprintf('%.0f', $r * 255);
        $g = sprintf('%.0f', $g * 255);
        $b = sprintf('%.0f', $b * 255);
    }

    $rgb->{r} = $r;
    $rgb->{g} = $g;
    $rgb->{b} = $b;
    return $rgb;
}
  

sub _rgb {
    my ($self, $hex) = @_;
    return (hex(substr($hex,0,2)),
            hex(substr($hex,2,2)),
            hex(substr($hex,4,2)));
}


sub _shift_hue {
    my ($self, $hue, $angle) = @_;
    return ($hue + $angle) % 360;
}


sub _get_named_color {
    my ($self, $color_name) = @_;
    return $self->_get_color_names->{$color_name};
}


sub _setup_colors {
    my ($self) = @_;
    $self->{colors} = {qw(
        aliceblue f0f8ff         
        antiquewhite faebd7    
        aqua 00ffff          
        aquamarine 7fffd4
        azure f0ffff             
        beige f5f5dc           
        bisque ffe4c4        
        black 000000
        blanchedalmond ffebcd    
        blue 0000ff            
        blueviolet 8a2be2    
        brown a52a2a
        burlywood deb887         
        cadetblue 5f9ea0       
        chartreuse 7fff00    
        chocolate d2691e
        coral ff7f50             
        cornflowerblue 6495ed  
        cornsilk fff8dc      
        crimson dc143c 
        cyan  00ffff             
        darkblue  00008b       
        darkcyan  008b8b     
        darkgoldenrod  b8860b 
        darkgray  a9a9a9  
        darkgreen  006400 
        darkgrey  a9a9a9 
        darkkhaki  bdb76b 
        darkmagenta  8b008b 
        darkolivegreen  556b2f 
        darkorange  ff8c00  
        darkorchid  9932cc 
        darkred  8b0000  
        darksalmon  e9967a 
        darkseagreen  8fbc8f 
        darkslateblue  483d8b 
        darkslategray  2f4f4f 
        darkslategrey  2f4f4f 
        darkturquoise  00ced1 
        darkviolet  9400d3 
        deeppink  ff1493  
        deepskyblue  00bfff 
        dimgray  696969 
        dimgrey  696969 
        dodgerblue  1e90ff 
        firebrick  b22222 
        floralwhite  fffaf0  
        forestgreen  228b22 
        fuchsia  ff00ff 
        gainsboro  dcdcdc 
        ghostwhite  f8f8ff 
        gold  ffd700 
        goldenrod  daa520 
        gray  808080 
        green  008000 
        greenyellow  adff2f 
        grey  808080 
        honeydew  f0fff0 
        hotpink  ff69b4 
        indianred  cd5c5c 
        indigo  4b0082 
        ivory  fffff0 
        khaki  f0e68c 
        lavender  e6e6fa 
        lavenderblush  fff0f5 
        lawngreen  7cfc00 
        lemonchiffon  fffacd 
        lightblue  add8e6 
        lightcoral  f08080 
        lightcyan  e0ffff 
        lightgoldenrodyellow  fafad2 
        lightgray  d3d3d3 
        lightgreen  90ee90 
        lightgrey  d3d3d3 
        lightpink  ffb6c1 
        lightsalmon  ffa07a 
        lightseagreen  20b2aa 
        lightskyblue  87cefa 
        lightslategray  778899  
        lightslategrey  778899 
        lightsteelblue  b0c4de 
        lightyellow  ffffe0 
        lime  00ff00 
        limegreen  32cd32 
        linen  faf0e6 
        magenta  ff00ff 
        maroon  800000 
        mediumaquamarine  66cdaa 
        mediumblue  0000cd 
        mediumorchid  ba55d3 
        mediumpurple  9370db 
        mediumseagreen  3cb371 
        mediumslateblue  7b68ee 
        mediumspringgreen  00fa9a 
        mediumturquoise  48d1cc 
        mediumvioletred  c71585 
        midnightblue  191970 
        mintcream  f5fffa 
        mistyrose  ffe4e1 
        moccasin  ffe4b5 
        navajowhite  ffdead 
        navy  000080 
        oldlace  fdf5e6 
        olive  808000 
        olivedrab  6b8e23 
        orange  ffa500 
        orangered  ff4500 
        orchid  da70d6 
        palegoldenrod  eee8aa 
        palegreen  98fb98 
        paleturquoise  afeeee 
        palevioletred  db7093 
        papayawhip  ffefd5 
        peachpuff  ffdab9 
        peru  cd853f 
        pink  ffc0cb 
        plum  dda0dd 
        powderblue  b0e0e6 
        purple  800080 
        red  ff0000 
        rosybrown  bc8f8f 
        royalblue  4169e1 
        saddlebrown  8b4513 
        salmon  fa8072 
        sandybrown  f4a460 
        seagreen  2e8b57 
        seashell  fff5ee 
        sienna  a0522d 
        silver  c0c0c0 
        skyblue  87ceeb 
        slateblue  6a5acd 
        slategray  708090 
        slategrey  708090 
        snow  fffafa 
        springgreen  00ff7f 
        steelblue  4682b4 
        tan  d2b48c 
        teal  008080 
        thistle  d8bfd8 
        tomato  ff6347 
        turquoise  40e0d0 
        violet  ee82ee 
        wheat  f5deb3 
        white  ffffff 
        whitesmoke  f5f5f5 
        yellow  ffff00 
        yellowgreen  9acd32 
    )};
}


1;

__END__

=pod


=head1 NAME

Color::Mix - Generate themes from an RGB color wheel.


=head1 SYNOPSIS


  my $color = Color::Mix->new;     


  # Complementary to red
  my $complementary_color = $color->complementary('ff0000');  


  # Double complementary to red/yellow
  my ($color1, $color2) = $color->double_complementary('ff0000', 'ffff00');  
  my ($color1, $color2) = $color->double_complementary('red', 'yellow');  


  # Generate a default analogous color scheme for red
  my @analogous = $color->analogous('ff0000');  


  # Generate a more controlled analogous color scheme for blue
  # Give me 5 colors, slice the color wheel up into 36.
  # The defaults are 3 colors + the one passed in, 12 slices. 
  my @analogous = $color->analogous('0000ff', 5, 36);  


=head1 DESCRIPTION

Color::Mix is a lightweight color scheme generator for Perl. 
Users of this module are expected to know how to use RGB hexidecimal colors.

All the scheme methods take at the very minimum either an rgb hex code for the color you are trying to calculate or a color name from the common X11 color list. In addition to this the analogous method can take a number of arguments to gain fine grained control over the scheme generated through controlling the color range.

The colors are calculated against an RGB color wheel internally.

Note: This module uses Red, Green and Blue for it's primary colours which differs from the normal
color theory of Red, Yellow and Blue. What this means is it uses HSV-to-RGB to calculate the schemes
so should behave in the same way as the color wheel in popular image manipulation apps like Gimp &
Photoshop.


This module doesn't have any dependencies and should run on any modern-ish version of Perl 5. Tested
on 5.8


=head1 METHODS

=head2 new()

 my $color = Color::Mix->new();

Create a new instance of the Color::Mix class;


=head2 complementary()

 my $complementary_color = $color->complementary('ff0000'); 

Given a hex color code as a parameter the complementary() method returns 
a hexidecimal color of the parameters complement.
A complimentary color is one who is on the opposite side of the color
wheel in this case an RGB color wheel.

When mixed togther the two colours should produce a grey if the colors
are complementary. An easy way to test this is to use the Blend Tool
in Gimp.


=head2 double_complementary()

 my ($color1, $color2) = $color->double_complementary('ff0000', 'ffff00');

Given two hexadecimal color codes as parameters, this method calculates
both their complements and returns them in an array.


=head2 analogous()

 my @analogous = $color->analogous('0000ff', 5, 36);

Analogous color schemes are ones in which the colors lie next to each
other on the color wheel.

By default this method splits up the colorwheel into 12 pieces and
returns the next 3 pieces of the wheel. So using this if you entered
0000ff (blue) then by default you would get back '80000ff' (purple), 
'ff00ff' (pink) and 'ff0080' (hotpink) colors.

If you split the wheel up into 36 as in the example above you essentially
reduce the range of the colors by 3. So now if you entered 0000ff (blue)
but added a parameter 3 (For number of colors you want returned) and
36 (To split the wheel up into 36 pieces) then you would get back
'2b00ff' (Blue), '5500ff' (Bluey Purple) and '8000ff' (Purple).

This gives and easy way to either limit or expand the range of the 
analogous color palette.


=head2 trinary()

 my @trinary = $color->trinary('ff0000');
 my @trinary = $color->trinary('limegreen');

Given a hexidecimal color the trinary method will calculated two other
colors that are evenly spaced around the RGB color wheel. 

So for the example given above where red is passed into the method 
the results would be 'ff0000' (Red), '00ff00' (Green), '0000ff' (Blue).

If you want three really different colours for your web site/app then
this method is a good one to use.


=head2 lighten()

 my $lightened = $color->lighten('660000');
 my $lightened = $color->lighten('darkred');
 my $lightened = $color->lighten('660000', 2);

The lighten method will take a given color and increase the value
of each of the RGB components of the color by 32 (default).

If a second parameter is present it will use this and multiply the
32 by it. So in the second example above it will increase each of
the RGB components by 32 x 2 = 64. When the value of any of the RGB
components gets to 255 it stops increasing it's value.

This method is useful if one of the colors generated by any of the 
methods above is a little too dark for your liking, just pass the
color to the lighten method to get a lighter version.


=head2 darken()

 my $darkened = $color->darken('ffff00');
 my $darkened = $color->darken('yellow');
 my $darkened = $color->darken('ffff00', 2);

In opposite to the lighten method above, the darken method will take
a given color and decrease each of it's RGB components by 32 in it's
default setting.

If a second parameter is present it will use this and multiply the 32
by it. So in the second example above it will decrease each of the
RGB components by 32 x 2 = 64. When the value of any of the RGB components
is at 0, it will not decrease it's value any more.

I find this method useful to generate borders when I know the background color,
you can get a yellow background, with a dark gold colored border just by passing
the yellow color into the darken method.


=head2 get_color()

 my $hex = $color->get_color('limegreen'); # hex will be 32cd32

If given a valid color name from the W3C X11 Colors list (Which is the
same as the SVG 1.0 color list, return the RGB hex for the given
color name. If a valid hex RGB number is given as a parameter it
just returns it.


=head2 get_color_list()

 my @colors = $color->get_color_list;

This returns the valid list of named colors known to Color::Mix. The list
was generated from W3C sites listing of X11 colors which are the same as
the SVG 1.0 color list.


=head2 set_shade()

 $color->set_shade(1);

This alters the behavious of both the lighten and darken methods. By default
Color::Mix makes this value 32 decimal which changes 000000 to 202020 using
the lighten method. If we set the shade value to 1 decimal then making the
same call would lighten 000000 to 010101.


=head2 get_shade()

 my $current_shade = $color->get_shade;

This method returns the current shade value that is being used. The default
is 32, but can be changed by calling the set_shade method described above.


=head1 SEE ALSO

L<Color::Scheme> if you want your schemes generated by Red, Yellow, Blue instead
of the css based Red, Green, Blue.

=head1 AUTHOR

Lee Dalton E<lt>leedalton@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Lee Dalton.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

