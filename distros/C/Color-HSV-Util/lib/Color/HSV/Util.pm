package Color::HSV::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-06'; # DATE
our $DIST = 'Color-HSV-Util'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Color::RGB::Util ();

use Exporter 'import';
our @EXPORT_OK = qw(
                       hsl2hsv
                       hsv2hsl
                       hsv2rgb
                       rgb2hsv
               );

for (@EXPORT_OK) {
    *{$_} = \&{"Color::RGB::Util::$_"};
}

1;
# ABSTRACT: Utilities related to HSV color space

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::HSV::Util - Utilities related to HSV color space

=head1 VERSION

This document describes version 0.003 of Color::HSV::Util (from Perl distribution Color-HSV-Util), released on 2021-08-06.

=head1 SYNOPSIS

 use Color::HSV::Util qw(
                       hsl2hsv
                       hsv2hsl
                       hsv2rgb
                       rgb2hsv
 );

=head1 DESCRIPTION

HSV color value is written using this notation:

 H S V

that is, three floating point numbers separated by a single space. Examples:

 0 1 1                     # red (RGB ff0000)
 120 0.498 1               # light green (RGB 80ff80)

=head1 FUNCTIONS

=head2 hsl2hsv

=head2 hsv2hsl

=head2 hsv2rgb

=head2 rgb2hsv

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Color-HSV-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Color-HSV-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Color-HSV-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Color::RGB::Util>

L<Color::HSL::Util>

L<Color::ANSI::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
