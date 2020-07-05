package ColorTheme::Harmony::Monochromatic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'ColorTheme-Harmony-Monochromatic'; # DIST
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;
use parent 'ColorThemeBase::Static::FromObjectColors';

# TODO: allow some colors to have a different saturation, like in
# color.adobe.com

our %THEME = (
    v => 2,
    summary => 'Create a monochromatic color theme',
    description => <<'_',

All the colors in the theme will have the same hue *h*, but different saturation
(between *s1* and *s2*) and brightness (between *v1* and *v2*).

Example to see on the terminal:

    % show-color-theme-swatch Harmony::Monochromatic=h,86

_
    dynamic => 1,
    args => {
        n => {
            summary => 'Number of colors in the theme',
            schema => ['posodd*', max=>99], # give a sane maximum
            default => 5,
        },
        h => {
            summary => 'Hue of the colors',
            schema => ['num*', between=>[0, 360]],
            req => 1,
        },
        s1 => {
            summary => 'The left extreme of saturation',
            schema => ['num*', between=>[0, 1]],
            default => 0.75,
        },
        s2 => {
            summary => 'The right extreme of saturation',
            schema => ['num*', between=>[0, 1]],
            default => 0.25,
        },
        v1 => {
            summary => 'The left extreme of brightness',
            schema => ['num*', between=>[0, 1]],
            default => 1,
        },
        v2 => {
            summary => 'The right extreme of brightness',
            schema => ['num*', between=>[0, 1]],
            default => 0.5,
        },
    },
    examples => [
        {
            summary => 'A monochromatic red scheme',
            args => { h => 0 },
        },
    ],
);

sub new {
    require Color::RGB::Util;

    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my %colors;

    my $n = $self->{args}{n};
    my $h = $self->{args}{h};
    my $s1 = $self->{args}{s1};
    my $s2 = $self->{args}{s2};
    my $v1 = $self->{args}{v1};
    my $v2 = $self->{args}{v2};

    my $j_middle = int($n/2) + 1;

    my $s_dist = $n > 1 ? ($s2 - $s1) / ($n-1) : 0;
    my $v_dist = $n > 1 ? ($v2 - $v1) / ($n-1) : 0;

    for my $i (0..$n-1) {
        my $j = (($j_middle + $i*2 - 1) % $n) + 1;
        my $s = $s1 + $i*$s_dist;
        my $v = $v1 + $i*$v_dist;
        $colors{"color$j"} = Color::RGB::Util::hsv2rgb(sprintf "%d %.4f %.4f", $h, $s, $v);
    }

    $self->{items} = \%colors;
    $self;
}

1;
# ABSTRACT: Create a monochromatic color theme

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Harmony::Monochromatic - Create a monochromatic color theme

=head1 VERSION

This document describes version 0.005 of ColorTheme::Harmony::Monochromatic (from Perl distribution ColorTheme-Harmony-Monochromatic), released on 2020-06-19.

=head1 DESCRIPTION

All the colors in the theme will have the same hue I<h>, but different saturation
(between I<s1> and I<s2>) and brightness (between I<v1> and I<v2>).

Example to see on the terminal:

 % show-color-theme-swatch Harmony::Monochromatic=h,86

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorTheme-Harmony-Monochromatic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorTheme-Harmony-Monochromatic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorTheme-Harmony-Monochromatic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<ColorTheme::Harmony::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
