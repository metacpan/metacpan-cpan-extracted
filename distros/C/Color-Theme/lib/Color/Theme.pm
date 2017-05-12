package Color::Theme;

our $DATE = '2014-12-11'; # DATE
our $VERSION = '0.01'; # VERSION

1;
# ABSTRACT: Color theme structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::Theme - Color theme structure

=head1 VERSION

This document describes version 0.01 of Color::Theme (from Perl distribution Color-Theme), released on 2014-12-11.

=head1 DESCRIPTION

This module specifies a structure for color themes. The distribution also comes
with utility routines and roles for managing color themes in applications.

=head1 SPECIFICATION

Color theme is a L<DefHash> containing these keys: C<v> (float, should be 1.1),
C<name> (str), C<summary> (str), C<no_color> (bool, should be set to 1 if this
is a color theme without any colors), and C<colors> (hash, the colors for items;
hash keys are item names and hash values are color values).

A color value should be a scalar containing a single color code which is
6-hexdigit RGB color (e.g. C<ffc0c0>), or a hashref containing multiple color
codes, or a coderef which should produce a color code (or a hash of color
codes).

Multiple color codes are used to support foreground/background values or ANSI
color codes that are not representable by RGB, among other things. The keys are:
C<fg> (RGB value for foreground), C<bg> (RGB value for background), C<ansi_fg>
(ANSI color escape code for foreground), C<ansi_bg> (ANSI color escape code for
background). Future keys like C<css> can be defined.

Allowing coderef as color allows for flexibility, e.g. for doing gradation
border color, random color, etc. See, for example,
L<Text::ANSITable::ColorTheme::Demo>. Code will be called with C<< ($self,
%args) >> where C<%args> contains various information, like C<name> (the item
name being requested), etc. In Text::ANSITable, you can get the row position
from C<< $self->{_draw}{y} >>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Color-Theme>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Color-Theme>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Color-Theme>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
