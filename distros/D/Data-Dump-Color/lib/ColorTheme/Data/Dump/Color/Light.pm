package ColorTheme::Data::Dump::Color::Light;

use strict;
use parent 'ColorThemeBase::Static::FromStructColors';
use Term::ANSIColor;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-21'; # DATE
our $DIST = 'Data-Dump-Color'; # DIST
our $VERSION = '0.250'; # VERSION

sub _ansi16 {
    my ($fg, $bg) = @_;
    return {
        (defined $fg ? (ansi_fg=>color($fg)) : ()),
        (defined $bg ? (ansi_bg=>color($bg)) : ()),
    };
}

our %THEME = (
    v => 2,
    items => {
        Regexp  => 'ddbb00',
        undef   => 'ff6666',
        number  => 'aaaaff', # floats can have different color
        float   => '00ffff',
        string  => 'ffff88',
        object  => '00ff00',
        glob    => '00dddd',
        key     => 'ff77ff',
        comment => '00cc00',
        keyword => '', # blue
        symbol  => '00dddd',
        linum   => '808080',
    },
);

#use Data::Dump; dd \%THEME;

1;
# ABSTRACT: Light color theme for Data::Dump::Color (RGB 24bit)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Data::Dump::Color::Light - Light color theme for Data::Dump::Color (RGB 24bit)

=head1 VERSION

This document describes version 0.250 of ColorTheme::Data::Dump::Color::Light (from Perl distribution Data-Dump-Color), released on 2025-02-21.

=head1 DESCRIPTION

Blue, red, and purple are particularly not very visible with black background
and display's lower brightness. Thus this color theme.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-Color>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
