package Color::RGB::Util;

our $DATE = '2018-10-05'; # DATE
our $VERSION = '0.593'; # VERSION

use 5.010001;
use strict;
use warnings;

#use List::Util qw(min);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       mix_2_rgb_colors
                       mix_rgb_colors
                       rand_rgb_color
                       reverse_rgb_color
                       rgb2grayscale
                       rgb2sepia
                       rgb_luminance
                       tint_rgb_color
                       rgb_distance
                       rgb_diff
                       rgb_is_dark
                       rgb_is_light
               );

my $re_rgb = qr/\A#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\z/;

sub mix_2_rgb_colors {
    my ($rgb1, $rgb2, $pct) = @_;

    $pct //= 0.5;

    my ($r1, $g1, $b1) =
        $rgb1 =~ $re_rgb or die "Invalid rgb1 color, must be in 'ffffff' form";
    my ($r2, $g2, $b2) =
        $rgb2 =~ $re_rgb or die "Invalid rgb2 color, must be in 'ffffff' form";
    for ($r1, $g1, $b1, $r2, $g2, $b2) { $_ = hex $_ }

    return sprintf("%02x%02x%02x",
                   $r1 + $pct*($r2-$r1),
                   $g1 + $pct*($g2-$g1),
                   $b1 + $pct*($b2-$b1),
               );
}

sub mix_rgb_colors {

    my (@weights, @r, @g, @b);

    while (@_ >= 2) {
        my ($rgb, $weight) = splice @_, 0, 2;
        my ($r, $g, $b) = $rgb =~ $re_rgb
            or die "Invalid rgb color '$rgb', must be in 'ffffff' form";
        push @r, hex $r;
        push @g, hex $g;
        push @b, hex $b;
        push @weights, $weight;
    }
    my $tot_r = 0; for (0..$#r) { $tot_r += $r[$_]*$weights[$_] }
    my $tot_g = 0; for (0..$#g) { $tot_g += $g[$_]*$weights[$_] }
    my $tot_b = 0; for (0..$#b) { $tot_b += $b[$_]*$weights[$_] }
    my $tot_weight = 0; $tot_weight += $_ for @weights;
    die "Zero/negative total weight" unless $tot_weight > 0;

    return sprintf("%02x%02x%02x",
                   $tot_r / $tot_weight,
                   $tot_g / $tot_weight,
                   $tot_b / $tot_weight,
               );
}

sub rand_rgb_color {
    my ($rgb1, $rgb2) = @_;

    $rgb1 //= '000000';
    my ($r1, $g1, $b1) =
        $rgb1 =~ $re_rgb or die "Invalid rgb1 color, must be in 'ffffff' form";
    $rgb2 //= 'ffffff';
    my ($r2, $g2, $b2) =
        $rgb2 =~ $re_rgb or die "Invalid rgb2 color, must be in 'ffffff' form";
    for ($r1, $g1, $b1, $r2, $g2, $b2) { $_ = hex $_ }

    return sprintf("%02x%02x%02x",
                   $r1 + rand()*($r2-$r1+1),
                   $g1 + rand()*($g2-$g1+1),
                   $b1 + rand()*($b2-$b1+1),
               );
}

sub rgb2grayscale {
    my ($rgb) = @_;

    my ($r, $g, $b) =
        $rgb =~ $re_rgb or die "Invalid rgb color, must be in 'ffffff' form";
    for ($r, $g, $b) { $_ = hex $_ }

    # basically we just average the R, G, B
    my $avg = int(($r + $g + $b)/3);
    return sprintf("%02x%02x%02x", $avg, $avg, $avg);
}

sub rgb2sepia {
    my ($rgb) = @_;

    my ($r, $g, $b) =
        $rgb =~ $re_rgb or die "Invalid rgb color, must be in 'ffffff' form";
    for ($r, $g, $b) { $_ = hex $_ }

    # reference: http://www.techrepublic.com/blog/howdoi/how-do-i-convert-images-to-grayscale-and-sepia-tone-using-c/120
    my $or = ($r*0.393) + ($g*0.769) + ($b*0.189);
    my $og = ($r*0.349) + ($g*0.686) + ($b*0.168);
    my $ob = ($r*0.272) + ($g*0.534) + ($b*0.131);
    for ($or, $og, $ob) { $_ = 255 if $_ > 255 }
    return sprintf("%02x%02x%02x", $or, $og, $ob);
}

sub reverse_rgb_color {
    my ($rgb) = @_;

    my ($r, $g, $b) =
        $rgb =~ $re_rgb or die "Invalid rgb color, must be in 'ffffff' form";
    for ($r, $g, $b) { $_ = hex $_ }

    return sprintf("%02x%02x%02x", 255-$r, 255-$g, 255-$b);
}

sub _rgb_luminance {
    my ($r, $g, $b) = @_;
    0.2126*$r/255 + 0.7152*$g/255 + 0.0722*$b/255;
}

sub rgb_luminance {
    my ($rgb) = @_;

    my ($r, $g, $b) =
        $rgb =~ $re_rgb or die "Invalid rgb color, must be in 'ffffff' form";
    for ($r, $g, $b) { $_ = hex $_ }

    return _rgb_luminance($r, $g, $b);
}

sub tint_rgb_color {
    my ($rgb1, $rgb2, $pct) = @_;

    $pct //= 0.5;

    my ($r1, $g1, $b1) =
        $rgb1 =~ $re_rgb or die "Invalid rgb1 color, must be in 'ffffff' form";
    my ($r2, $g2, $b2) =
        $rgb2 =~ $re_rgb or die "Invalid rgb2 color, must be in 'ffffff' form";
    for ($r1, $g1, $b1, $r2, $g2, $b2) { $_ = hex $_ }

    my $lum = _rgb_luminance($r1, $g1, $b1);

    return sprintf("%02x%02x%02x",
                   $r1 + $pct*($r2-$r1)*$lum,
                   $g1 + $pct*($g2-$g1)*$lum,
                   $b1 + $pct*($b2-$b1)*$lum,
               );
}

sub rgb_distance {
    my ($rgb1, $rgb2) = @_;

    my ($r1, $g1, $b1) =
        $rgb1 =~ $re_rgb or die "Invalid rgb1 color, must be in 'ffffff' form";
    my ($r2, $g2, $b2) =
        $rgb2 =~ $re_rgb or die "Invalid rgb2 color, must be in 'ffffff' form";
    for ($r1, $g1, $b1, $r2, $g2, $b2) { $_ = hex $_ }

    (($r1-$r2)**2 + ($g1-$g2)**2 + ($b1-$b2)**2)**0.5;
}

sub rgb_diff {
    my ($rgb1, $rgb2, $algo) = @_;

    $algo //= 'euclidean';

    my ($r1, $g1, $b1) =
        $rgb1 =~ $re_rgb or die "Invalid rgb1 color, must be in 'ffffff' form";
    my ($r2, $g2, $b2) =
        $rgb2 =~ $re_rgb or die "Invalid rgb2 color, must be in 'ffffff' form";
    for ($r1, $g1, $b1, $r2, $g2, $b2) { $_ = hex $_ }

    my $dr2 = ($r1-$r2)**2;
    my $dg2 = ($g1-$g2)**2;
    my $db2 = ($b1-$b2)**2;

    if ($algo eq 'approx1') {
        my $rm = ($r1 + $r2)/2;
        (2*$dr2 + 4*$dg2 + 3*$db2 + $rm*($dr2 - $db2)/256 )**0.5;
    } else {
        # euclidean
        ($dr2 + $dg2 + $db2)**0.5;
    }
}

sub rgb_is_dark {
    my ($rgb) = @_;
    rgb_distance($rgb, "000000") < rgb_distance($rgb, "ffffff") ? 1:0;
}

sub rgb_is_light {
    my ($rgb) = @_;
    rgb_distance($rgb, "000000") > rgb_distance($rgb, "ffffff") ? 1:0;
}

1;
# ABSTRACT: Utilities related to RGB colors

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::RGB::Util - Utilities related to RGB colors

=head1 VERSION

This document describes version 0.593 of Color::RGB::Util (from Perl distribution Color-RGB-Util), released on 2018-10-05.

=head1 SYNOPSIS

 use Color::RGB::Util qw(
     mix_2_rgb_colors
     mix_rgb_colors
     rand_rgb_color
     rgb2grayscale
     rgb2sepia
     reverse_rgb_color
     rgb_luminance
     tint_rgb_color
     rgb_distance
     rgb_diff
     rgb_is_light
     rgb_is_dark
 );

 say mix_2_rgb_colors('#ff0000', '#ffffff');     # pink (red + white)
 say mix_2_rgb_colors('ff0000', 'ffffff', 0.75); # pink with a whiter shade

 say mix_rgb_colors('ff0000', 1, 'ffffff', 1);   # pink (red + white 1 : 1)
 say mix_rgb_colors('ff0000', 1, 'ffffff', 3);   # pink with a whiter shade (red + white 1 : 3)
 say mix_rgb_colors('ff0000', 1, 'ffffff', 1, '0000ff', 0.5);   # bluish pink

 say rand_rgb_color();
 say rand_rgb_color('000000', '333333');         # limit range

 say rgb2grayscale('0033CC');                    # => 555555

 say rgb2sepia('0033CC');                        # => 4d4535

 say reverse_rgb_color('0033CC');                # => ffcc33

 say rgb_luminance('d090aa');                    # => ffcc33

 say tint_rgb_color('#ff8800', '#0033cc');       # => b36e3c

 say rgb_distance('000000', '000000')            # => 0
 say rgb_distance('01f000', '04f400')            # => 5
 say rgb_distance('ffff00', 'ffffff')            # => 255

 say rgb_is_dark('404040');                      # => 1
 say rgb_is_dark('a0a0a0');                      # => 0
 say rgb_is_light('404040');                     # => 0
 say rgb_is_light('a0a0a0');                     # => 1

 say rgb_diff('000000', '000000');               # => 0
 say rgb_diff('01f000', '04f400');               # => 5
 say rgb_diff('ffff00', 'ffffff');               # => 255

 say rgb_diff('000000', '000000', 'approx1');    # => 0
 say rgb_diff('01f000', '04f400', 'approx1');    # => 9.06
 say rgb_diff('ffff00', 'ffffff', 'approx1');    # => 360.98

=head1 DESCRIPTION

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 mix_2_rgb_colors

Usage:

 my $mixed_rgb = mix_2_rgb_colors($rgb1, $rgb2, $pct);

Mix 2 RGB colors. C<$pct> is a number between 0 and 1, by default 0.5 (halfway),
the closer to 1 the closer the resulting color to C<$rgb2>.

=head2 mix_rgb_colors

Usage:

 my $mixed_rgb = mix_rgb_colors($color1, $weight1, $color2, $weight2, ...);

Mix several RGB colors.

=head2 rand_rgb_color

Usage:

 my $rgb = rand_rgb_color([ $low_limit [ , $high_limit ] ]);

Generate a random RGB color. You can specify the limit. Otherwise, they default
to the full range (000000 to ffffff).

=head2 rgb2grayscale

Usage:

 my $rgb_gs = rgb2grayscale($rgb);

Convert C<$rgb> to grayscale RGB value.

=head2 rgb2sepia

Usage:

 my $rgb_sepia = rgb2sepia($rgb);

Convert C<$rgb> to sepia tone RGB value.

=head2 reverse_rgb_color

Usage:

 my $reversed = reverse_rgb_color($rgb);

Reverse C<$rgb>.

=head2 rgb_luminance

Usage:

 my $luminance = rgb_luminance($rgb);

Calculate standard/objective luminance from RGB value using this formula:

 (0.2126*R) + (0.7152*G) + (0.0722*B)

where R, G, and B range from 0 to 1. Return a number from 0 to 1.

=head2 tint_rgb_color

Usage:

 my $new_rgb = tint_rgb_color($rgb, $tint_rgb, $pct)

Tint C<$rgb> with C<$tint_rgb>. $pct is by default 0.5. It is similar to mixing,
but the less luminance the color is the less it is tinted with the tint color.
This has the effect of black color still being black instead of becoming tinted.

=head2 rgb_distance

Usage:

 my $dist = rgb_distance($rgb1, $rgb2)

Calculate the euclidean RGB distance, using this formula:

 ( (R1-R2)**2 + (G1-G2)**2 + (B1-B2)**2 )**0.5

For example, the distance between "000000" and "ffffff" is ~441.67, while the
distance between "ffff00" and "ffffff" is 255.

=head2 rgb_diff

Usage:

 my $dist = rgb_diff($rgb1, $rgb2[ , $algo ])

Calculate difference between two RGB colors, using one of several algorithms.
The default ("euclidean") simply calculates the distance as:

 ( (R1-R2)**2 + (G1-G2)**2 + (B1-B2)**2 )**0.5

which is the same as what L</"rgb_distance">() would produce. Another algorithm
("approx1") uses the following formula:

 ( 2*(R1-R2)**2 + 4*(G1-G2)**2 + 3*(B1-B2)**2 + Rm*((R1-R2)**2 - (B1-B2)**2)/256 )**0.5

where, Rm or "R mean" is (R1+R2)/2.

For more details about color difference, refer to
L<https://en.wikipedia.org/wiki/Color_difference>.

=head2 rgb_is_dark

Usage:

 my $is_dark = rgb_is_dark($rgb)

Return true if C<$rgb> is a "dark" color, which is determined by checking if the
RGB distance to "000000" is smaller than to "ffffff".

=head2 rgb_is_light

Usage:

 my $is_light = rgb_is_light($rgb)

Return true if C<$rgb> is a "light" color, which is determined by checking if
the RGB distance to "000000" is larger than to "ffffff".

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Color-RGB-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Color-RGB-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Color-RGB-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Color::ANSI::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
