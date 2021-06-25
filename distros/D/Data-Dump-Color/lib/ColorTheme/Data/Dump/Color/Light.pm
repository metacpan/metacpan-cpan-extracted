package ColorTheme::Data::Dump::Color::Light;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-24'; # DATE
our $DIST = 'Data-Dump-Color'; # DIST
our $VERSION = '0.248'; # VERSION

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

This document describes version 0.248 of ColorTheme::Data::Dump::Color::Light (from Perl distribution Data-Dump-Color), released on 2021-06-24.

=head1 DESCRIPTION

Blue, red, and purple are particularly not very visible with black background
and display's lower brightness. Thus this color theme.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-Color>

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
