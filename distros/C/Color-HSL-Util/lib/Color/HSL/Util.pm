package Color::HSL::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-07'; # DATE
our $DIST = 'Color-HSL-Util'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Color::RGB::Util ();

use Exporter 'import';
our @EXPORT_OK = qw(
                       hsl2hsv
                       hsl2rgb
                       hsv2hsl
                       rgb2hsl
               );

for (@EXPORT_OK) {
    *{$_} = \&{"Color::RGB::Util::$_"};
}

1;
# ABSTRACT: Utilities related to HSL color space

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::HSL::Util - Utilities related to HSL color space

=head1 VERSION

This document describes version 0.001 of Color::HSL::Util (from Perl distribution Color-HSL-Util), released on 2020-06-07.

=head1 SYNOPSIS

 use Color::HSV::Util qw(
                       hsl2hsv
                       hsl2rgb
                       hsv2hsl
                       rgb2hsl
 );

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 hsl2hsv

=head2 hsl2rgb

=head2 hsv2hsl

=head2 rgb2hsl

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Color-HSL-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Color-HSL-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Color-HSL-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Color::RGB::Util>

L<Color::HSV::Util>

L<Color::ANSI::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
