package ColorTheme::Data::Dump::Color::Default16;

use strict;
use parent 'ColorThemeBase::Static::FromStructColors';
use Term::ANSIColor;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-03'; # DATE
our $DIST = 'Data-Dump-Color'; # DIST
our $VERSION = '0.249'; # VERSION

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
        Regexp  => _ansi16('yellow'),
        undef   => _ansi16('bright_red'),
        number  => _ansi16('bright_blue'), # floats can have different color
        float   => _ansi16('cyan'),
        string  => _ansi16('bright_yellow'),
        object  => _ansi16('bright_green'),
        glob    => _ansi16('bright_cyan'),
        key     => _ansi16('magenta'),
        comment => _ansi16('green'),
        keyword => _ansi16('blue'),
        symbol  => _ansi16('cyan'),
        linum   => _ansi16('black', 'on_white'), # file:line number
    },
);

#use Data::Dump; dd \%THEME;

1;
# ABSTRACT: Default color theme for Data::Dump::Color (16 color)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Data::Dump::Color::Default16 - Default color theme for Data::Dump::Color (16 color)

=head1 VERSION

This document describes version 0.249 of ColorTheme::Data::Dump::Color::Default16 (from Perl distribution Data-Dump-Color), released on 2023-02-03.

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

This software is copyright (c) 2023, 2021, 2018, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
