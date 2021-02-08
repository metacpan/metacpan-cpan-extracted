package ColorTheme::Data::Dump::Color::Default16;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-06'; # DATE
our $DIST = 'Data-Dump-Color'; # DIST
our $VERSION = '0.242'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';
use Term::ANSIColor;

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

This document describes version 0.242 of ColorTheme::Data::Dump::Color::Default16 (from Perl distribution Data-Dump-Color), released on 2021-02-06.

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
