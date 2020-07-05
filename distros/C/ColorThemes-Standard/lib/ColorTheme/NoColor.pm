package ColorTheme::NoColor;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'ColorThemes-Standard'; # DIST
our $VERSION = '0.002'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';

our %THEME = (
    v => 2,
    summary => 'An empty color theme that provides no items',
    items => {},
    _no_color => 1,
);

1;
# ABSTRACT: An empty color theme that provides no items

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::NoColor - An empty color theme that provides no items

=head1 VERSION

This document describes version 0.002 of ColorTheme::NoColor (from Perl distribution ColorThemes-Standard), released on 2020-06-19.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemes-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemes-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemes-Standard>

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
