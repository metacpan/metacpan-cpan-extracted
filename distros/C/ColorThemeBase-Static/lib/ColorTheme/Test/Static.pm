package ColorTheme::Test::Static;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-09'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;
use parent 'ColorThemeBase::Static::FromStructColors';
use Color::RGB::Util 'rand_rgb_color';

our %THEME = (
    v => 2,
    summary => 'A simple color theme',
    items => {
        color1 => 'ff0000',
        color2 => '00ff00',
        color3 => {bg=>'0000ff'},
        color4 => {fg=>'000000', bg=>'ffffff'},
        color5 => sub {
            +{
                summary => 'A random foreground color',
                fg => rand_rgb_color(),
            };
        },
    },
);

1;
# ABSTRACT: A color theme with static list of colors

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Test::Static - A color theme with static list of colors

=head1 VERSION

This document describes version 0.006 of ColorTheme::Test::Static (from Perl distribution ColorThemeBase-Static), released on 2020-06-09.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeBase-Static>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
