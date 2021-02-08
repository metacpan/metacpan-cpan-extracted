package ColorTheme::Data::Dump::Color::Default256;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-06'; # DATE
our $DIST = 'Data-Dump-Color'; # DIST
our $VERSION = '0.242'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';

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

This document describes version 0.242 of ColorTheme::Data::Dump::Color::Default256 (from Perl distribution Data-Dump-Color), released on 2021-02-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Data-Dump-Color/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
