package ColorTheme::Search::Light;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-09'; # DATE
our $DIST = 'ColorTheme-Search-Light'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;
use parent 'ColorThemeBase::Static';

our %THEME = (
    v => 2,
    summary => 'Light theme for text viewer/search application',
    description => <<'_',

`ColorTheme::Search::*` can be used for text viewer/search applications, e.g.
grep or grep-like tools.

_
    examples => [
    ],
    items => {
        highlight => 'ff6666', # highlighted text
        location  => 'ff66ff', # location
        separator => '00dddd', # separator character
    },
);

1;
# ABSTRACT: Light theme for text viewer/search application

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Search::Light - Light theme for text viewer/search application

=head1 VERSION

This document describes version 0.001 of ColorTheme::Search::Light (from Perl distribution ColorTheme-Search-Light), released on 2021-06-09.

=head1 DESCRIPTION

C<ColorTheme::Search::*> can be used for text viewer/search applications, e.g.
grep or grep-like tools.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorTheme-Search-Light>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorTheme-Search-Light>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorTheme-Search-Light>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
