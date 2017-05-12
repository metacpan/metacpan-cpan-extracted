package Color::RGB::Util;

our $DATE = '2015-01-03'; # DATE
our $VERSION = '0.58'; # VERSION

use 5.010001;
use strict;
use warnings;

#use List::Util qw(min);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       mix_2_rgb_colors
                       rand_rgb_color
                       reverse_rgb_color
                       rgb2grayscale
                       rgb2sepia
                       rgb_luminance
                       tint_rgb_color
               );

sub mix_2_rgb_colors {
    my ($rgb1, $rgb2, $pct) = @_;

    $pct //= 0.5;

    $rgb1 =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb1 color, must be in 'ffffff' form";
    my $r1 = hex($1);
    my $g1 = hex($2);
    my $b1 = hex($3);
    $rgb2 =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb2 color, must be in 'ffffff' form";
    my $r2 = hex($1);
    my $g2 = hex($2);
    my $b2 = hex($3);

    return sprintf("%02x%02x%02x",
                   $r1 + $pct*($r2-$r1),
                   $g1 + $pct*($g2-$g1),
                   $b1 + $pct*($b2-$b1),
               );
}

sub rand_rgb_color {
    my ($rgb1, $rgb2) = @_;

    $rgb1 //= '000000';
    $rgb1 =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb1 color, must be in 'ffffff' form";
    my $r1 = hex($1);
    my $g1 = hex($2);
    my $b1 = hex($3);
    $rgb2 //= 'ffffff';
    $rgb2 =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb2 color, must be in 'ffffff' form";
    my $r2 = hex($1);
    my $g2 = hex($2);
    my $b2 = hex($3);

    return sprintf("%02x%02x%02x",
                   $r1 + rand()*($r2-$r1+1),
                   $g1 + rand()*($g2-$g1+1),
                   $b1 + rand()*($b2-$b1+1),
               );
}

sub rgb2grayscale {
    my ($rgb) = @_;

    $rgb =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb color, must be in 'ffffff' form";
    my $r = hex($1);
    my $g = hex($2);
    my $b = hex($3);

    # basically we just average the R, G, B
    my $avg = int(($r + $g + $b)/3);
    return sprintf("%02x%02x%02x", $avg, $avg, $avg);
}

sub rgb2sepia {
    my ($rgb) = @_;

    $rgb =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb color, must be in 'ffffff' form";
    my $r = hex($1);
    my $g = hex($2);
    my $b = hex($3);

    # reference: http://www.techrepublic.com/blog/howdoi/how-do-i-convert-images-to-grayscale-and-sepia-tone-using-c/120
    my $or = ($r*0.393) + ($g*0.769) + ($b*0.189);
    my $og = ($r*0.349) + ($g*0.686) + ($b*0.168);
    my $ob = ($r*0.272) + ($g*0.534) + ($b*0.131);
    for ($or, $og, $ob) { $_ = 255 if $_ > 255 }
    return sprintf("%02x%02x%02x", $or, $og, $ob);
}

sub reverse_rgb_color {
    my ($rgb) = @_;

    $rgb =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb color, must be in 'ffffff' form";
    my $r = hex($1);
    my $g = hex($2);
    my $b = hex($3);

    return sprintf("%02x%02x%02x", 255-$r, 255-$g, 255-$b);
}

sub _rgb_luminance {
    my ($r, $g, $b) = @_;
    0.2126*$r/255 + 0.7152*$g/255 + 0.0722*$b/255;
}

sub rgb_luminance {
    my ($rgb) = @_;

    $rgb =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb color, must be in 'ffffff' form";
    my $r = hex($1);
    my $g = hex($2);
    my $b = hex($3);

    return _rgb_luminance($r, $g, $b);
}

sub tint_rgb_color {
    my ($rgb1, $rgb2, $pct) = @_;

    $pct //= 0.5;

    $rgb1 =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb color, must be in 'ffffff' form";
    my $r1 = hex($1);
    my $g1 = hex($2);
    my $b1 = hex($3);
    $rgb2 =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid tint color, must be in 'ffffff' form";
    my $r2 = hex($1);
    my $g2 = hex($2);
    my $b2 = hex($3);

    my $lum = _rgb_luminance($r1, $g1, $b1);

    return sprintf("%02x%02x%02x",
                   $r1 + $pct*($r2-$r1)*$lum,
                   $g1 + $pct*($g2-$g1)*$lum,
                   $b1 + $pct*($b2-$b1)*$lum,
               );
}

1;
# ABSTRACT: Utilities related to RGB colors

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::RGB::Util - Utilities related to RGB colors

=head1 VERSION

This document describes version 0.58 of Color::RGB::Util (from Perl distribution Color-RGB-Util), released on 2015-01-03.

=head1 SYNOPSIS

 use Color::RGB::Util qw(
     mix_2_rgb_colors
     rand_rgb_color
     rgb2grayscale
     rgb2sepia
     reverse_rgb_color
     rgb_luminance
 );

 say mix_2_rgb_colors('#ff0000', '#ffffff');     # pink (red + white)
 say mix_2_rgb_colors('ff0000', 'ffffff', 0.75); # pink with a whiter shade

 say rand_rgb_color();
 say rand_rgb_color('000000', '333333');         # limit range

 say rgb2grayscale('0033CC');                    # => 555555

 say rgb2sepia('0033CC');                        # => 4d4535

 say reverse_rgb_color('0033CC');                # => ffcc33

 say rgb_luminance('d090aa');                    # => ffcc33

=head1 DESCRIPTION

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 mix_2_rgb_colors($rgb1, $rgb2, $pct) => STR

Mix 2 RGB colors. C<$pct> is a number between 0 and 1, by default 0.5 (halfway),
the closer to 1 the closer the resulting color to C<$rgb2>.

=head2 rand_rgb_color([$low_limit[, $high_limit]]) => STR

Generate a random RGB color. You can specify the limit. Otherwise, they default
to the full range (000000 to ffffff).

=head2 rgb2grayscale($rgb) => RGB

Convert C<$rgb> to grayscale RGB value.

=head2 rgb2sepia($rgb) => RGB

Convert C<$rgb> to sepia tone RGB value.

=head2 reverse_rgb_color($rgb) => RGB

Reverse C<$rgb>.

=head2 rgb_luminance($rgb) => NUM

Calculate standard/objective luminance from RGB value using this formula:

 (0.2126*R) + (0.7152*G) + (0.0722*B)

where R, G, and B range from 0 to 1. Return a number from 0 to 1.

=head2 tint_rgb_color($rgb, $tint_rgb, $pct) => RGB

Tint C<$rgb> with C<$tint_rgb>. $pct is by default 0.5. It is similar to mixing,
but the less luminance the color is the less it is tinted with the tint color.
This has the effect of black color still being black instead of becoming tinted.

=head1 SEE ALSO

L<Color::ANSI::Util>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Color-RGB-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-Color-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Color-RGB-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
