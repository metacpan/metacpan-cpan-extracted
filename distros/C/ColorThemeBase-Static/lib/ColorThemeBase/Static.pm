package ColorThemeBase::Static;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.008'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';

1;
# ABSTRACT: Base class for color theme modules with static list of items (from object's colors key)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorThemeBase::Static - Base class for color theme modules with static list of items (from object's colors key)

=head1 VERSION

This document describes version 0.008 of ColorThemeBase::Static (from Perl distribution ColorThemeBase-Static), released on 2020-06-19.

=head1 DESCRIPTION

This class is now alias for L<ColorThemeBase::Static::FromStructColors>. You can
use that class directly.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeBase-Static>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ColorThemeBase::Static::FromStructColors>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
