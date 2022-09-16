use v5.12;

# check, convert and measure color values

package App::GUI::Harmonograph::Color::Value;
use Carp;
use Exporter 'import';
our @EXPORT_OK = qw/check_rgb check_hsl trim_rgb trim_hsl 
    difference_rgb difference_hsl distance_rgb distance_hsl 
    hsl_from_rgb rgb_from_hsl hex_from_rgb rgb_from_hex/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);


sub check_rgb { # carp returns 1
    my (@rgb) = @_;
    my $help = 'has to be an integer between 0 and 255';
    return carp "need exactly 3 positive integer values 0 <= n < 256 for rgb input" unless @rgb == 3;
    return carp "red value $rgb[0] ".$help   unless int $rgb[0] == $rgb[0] and $rgb[0] >= 0 and $rgb[0] < 256;
    return carp "green value $rgb[1] ".$help unless int $rgb[1] == $rgb[1] and $rgb[1] >= 0 and $rgb[1] < 256;
    return carp "blue value $rgb[2] ".$help  unless int $rgb[2] == $rgb[2] and $rgb[2] >= 0 and $rgb[2] < 256;
    0;
}

sub check_hsl {
    my (@hsl) = @_;
    my $help = 'has to be an integer between 0 and';
    return carp "need exactly 3 positive integer between 0 and 359 or 99 for hsl input" unless @hsl == 3;
    return carp "hue value $hsl[0] $help 359"        unless int $hsl[0] == $hsl[0] and $hsl[0] >= 0 and $hsl[0] < 360;
    return carp "saturation value $hsl[1] $help 100" unless int $hsl[1] == $hsl[1] and $hsl[1] >= 0 and $hsl[1] < 101;
    return carp "lightness value $hsl[2] $help 100"  unless int $hsl[2] == $hsl[2] and $hsl[2] >= 0 and $hsl[2] < 101;
    0;
}

sub trim_rgb { # cut values into the domain of definition of 0 .. 255
    my (@rgb) = @_;
    return (0,0,0) unless @rgb == 3;
    for (0..2){
        $rgb[$_] =   0 if $rgb[$_] <   0;
        $rgb[$_] = 255 if $rgb[$_] > 255;
    }
    $rgb[$_] = round($rgb[$_]) for 0..2;
    @rgb;
}

sub trim_hsl { # cut values into 0 ..359, 0 .. 100, 0 .. 100
    my (@hsl) = @_;
    return (0,0,0) unless @hsl == 3;
    $hsl[0] += 360 while $hsl[0] <    0;
    $hsl[0] -= 360 while $hsl[0] >= 360;
    for (1..2){ 
        $hsl[$_] =   0 if $hsl[$_] <   0;
        $hsl[$_] = 100 if $hsl[$_] > 100; 
    }
    $hsl[$_] = round($hsl[$_]) for 0..2;
    @hsl;
}

sub difference_rgb { # \@rgb, \@rgb --> @rgb             distance as vector
    my ($rgb, $rgb2) = @_;               
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb differences" 
        unless ref $rgb eq 'ARRAY' and @$rgb == 3 and ref $rgb2 eq 'ARRAY' and @$rgb2 == 3;
    check_rgb(@$rgb) and return;
    check_rgb(@$rgb2) and return;
    (abs($rgb->[0] - $rgb2->[0]), abs($rgb->[1] - $rgb2->[1]), abs($rgb->[2] - $rgb2->[2]) );
}

sub difference_hsl { # \@hsl, \@hsl --> $d
    my ($hsl, $hsl2) = @_;
    return carp  "need two triplets of hsl values in 2 arrays to compute hsl differences"
        unless ref $hsl eq 'ARRAY' and @$hsl == 3 and ref $hsl2 eq 'ARRAY' and @$hsl2 == 3;
    check_hsl(@$hsl) and return;
    check_hsl(@$hsl2) and return;
    my $delta_h = abs($hsl->[0] - $hsl2->[0]);
    $delta_h = 360 - $delta_h if $delta_h > 180;
    ($delta_h, abs($hsl->[1] - $hsl2->[1]), abs($hsl->[2] - $hsl2->[2]) );
}

sub distance_rgb { # \@rgb, \@rgb --> $d
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb distance " if @_ != 2;
    my @delta_rgb = difference_rgb( $_[0], $_[1] );
    return unless @delta_rgb == 3;
    sqrt($delta_rgb[0] ** 2 + $delta_rgb[1] ** 2 + $delta_rgb[2] ** 2); 
}

sub distance_hsl { # \@hsl, \@hsl --> $d
    return carp  "need two triplets of hsl values in 2 arrays to compute hsl distance " if @_ != 2;
    my @delta_hsl = difference_hsl( $_[0], $_[1] );
    return unless @delta_hsl == 3;
    sqrt($delta_hsl[0] ** 2 + $delta_hsl[1] ** 2 + $delta_hsl[2] ** 2); 
}

sub hsl_from_rgb { # convert color value triplet (int --> int), (real --> real) if $real
    my (@rgb) = @_;
    my $real = '';
    if (ref $rgb[0] eq 'ARRAY'){
        @rgb = @{$rgb[0]};
        $real = $rgb[1] // $real;
    }
    check_rgb( @rgb ) and return unless $real;
    my @hsl = _hsl_from_rgb( @rgb );
    return @hsl if $real;
    ( round( $hsl[0] ), round( $hsl[1] ), round( $hsl[2] ) );
}

sub rgb_from_hsl { # convert color value triplet (int > int), (real > real) if $real
    my (@hsl) = @_;
    my $real = '';
    if (ref $hsl[0] eq 'ARRAY'){
        @hsl = @{$hsl[0]};
        $real = $hsl[1] // $real;
    }
    check_hsl( @hsl ) and return unless $real;
    my @rgb = _rgb_from_hsl( @hsl );
    return @rgb if $real;
    ( round( $rgb[0] ), round( $rgb[1] ), round( $rgb[2] ) );
}

sub hex_from_rgb {  return unless @_ == 3;  sprintf "#%02x%02x%02x", @_ }
sub rgb_from_hex { # translate #000000 and #000 --> r, g, b
    my $hex = shift;
    return carp "hex color definition '$hex' has to start with # followed by 3 or 6 hex characters (0-9,a-f)" 
        unless defined $hex and (length($hex) == 4 or length($hex) == 7) and $hex =~ /^#[\da-f]+$/i;
    $hex = substr $hex, 1;
    (length $hex == 3) ? (map { hex($_.$_) } unpack( "a1 a1 a1", $hex)) 
                       : (map { hex($_   ) } unpack( "a2 a2 a2", $hex));
}

sub _hsl_from_rgb { # float conversion
    my (@rgb) = @_;
    my ($maxi, $mini) = (0 , 1);   # index of max and min value in @rgb
    if    ($rgb[1] > $rgb[0])      { ($maxi, $mini ) = ($mini, $maxi ) }
    if    ($rgb[2] > $rgb[$maxi])  {  $maxi = 2 }
    elsif ($rgb[2] < $rgb[$mini])  {  $mini = 2 }
    my $delta = $rgb[$maxi] - $rgb[$mini];
    my $avg = ($rgb[$maxi] + $rgb[$mini]) / 2;
    my $H = !$delta ? 0 : (2 * $maxi + (($rgb[($maxi+1) % 3] - $rgb[($maxi+2) % 3]) / $delta)) * 60;
    $H += 360 if $H < 0;
    my $S = ($avg == 0) ? 0 : ($avg == 255) ? 0 : $delta / (255 - abs((2 * $avg) - 255));
    ($H, $S * 100, $avg * 0.392156863 );
}

sub _rgb_from_hsl { # float conversion
    my (@hsl) = @_;
    $hsl[0] /= 60;
    my $C = $hsl[1] * (100 - abs($hsl[2] * 2 - 100)) * 0.0255;
    my $X = $C * (1 - abs($hsl[0] % 2 - 1 + ($hsl[0] - int $hsl[0])));
    my $m = ($hsl[2] * 2.55) - ($C / 2);
    return ($hsl[0] < 1) ? ($C + $m, $X + $m,      $m)
         : ($hsl[0] < 2) ? ($X + $m, $C + $m,      $m)
         : ($hsl[0] < 3) ? (     $m, $C + $m, $X + $m)
         : ($hsl[0] < 4) ? (     $m, $X + $m, $C + $m)
         : ($hsl[0] < 5) ? ($X + $m,      $m, $C + $m)
         :                 ($C + $m,      $m, $X + $m);
}

my $half = 0.50000000000008;

sub round {
    $_[0] >= 0 ? int ($_[0] + $half)
               : int ($_[0] - $half)
}


1;
