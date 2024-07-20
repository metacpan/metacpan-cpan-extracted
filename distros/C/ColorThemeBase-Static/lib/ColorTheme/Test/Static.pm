package ColorTheme::Test::Static;

use strict;
use warnings;
use parent 'ColorThemeBase::Static::FromStructColors';

use Color::RGB::Util 'rand_rgb_color';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.009'; # VERSION

our %THEME = (
    v => 2,
    summary => 'A static color theme',
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
# ABSTRACT: A static color theme

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Test::Static - A static color theme

=head1 VERSION

This document describes version 0.009 of ColorTheme::Test::Static (from Perl distribution ColorThemeBase-Static), released on 2024-07-17.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeBase-Static>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
