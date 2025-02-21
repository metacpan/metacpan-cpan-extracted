package ColorTheme::Data::Dump::Color::Default256;

use strict;
use parent 'ColorThemeBase::Static::FromStructColors';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-21'; # DATE
our $DIST = 'Data-Dump-Color'; # DIST
our $VERSION = '0.250'; # VERSION

sub _ansi256fg {
    my $code = shift;
    return {ansi_fg=>"\e[38;5;${code}m"};
}

our %THEME = (
    v => 2,
    items => {
        Regexp  => _ansi256fg(135),
        undef   => _ansi256fg(124),
        number  => _ansi256fg(27),
        float   => _ansi256fg(51),
        string  => _ansi256fg(226),
        object  => _ansi256fg(10),
        glob    => _ansi256fg(10),
        key     => _ansi256fg(202),
        comment => _ansi256fg(34),
        keyword => _ansi256fg(21),
        symbol  => _ansi256fg(51),
        linum   => _ansi256fg(10),
    },
);

1;
# ABSTRACT: Default color theme for Data::Dump::Color (256 color)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Data::Dump::Color::Default256 - Default color theme for Data::Dump::Color (256 color)

=head1 VERSION

This document describes version 0.250 of ColorTheme::Data::Dump::Color::Default256 (from Perl distribution Data-Dump-Color), released on 2025-02-21.

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
