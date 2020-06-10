package ColorThemeRole::ANSI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-09'; # DATE
our $DIST = 'ColorThemeRole-ANSI'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

use ColorThemeUtil::ANSI ();

sub get_item_color_as_ansi {
    my $self = shift;
    ColorThemeUtil::ANSI::item_color_to_ansi($self->get_item_color(@_));
}

1;
# ABSTRACT: Roles for using ColorTheme::* with ANSI codes

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorThemeRole::ANSI - Roles for using ColorTheme::* with ANSI codes

=head1 VERSION

This document describes version 0.001 of ColorThemeRole::ANSI (from Perl distribution ColorThemeRole-ANSI), released on 2020-06-09.

=head1 DESCRIPTION

Can be mixed in with a C<ColorTheme::*> class. Handy when using color theme in
terminal.

=head1 PROVIDED METHODS

=head2 get_item_color_as_ansi

Like get_item_color(), but returns color already converted to ANSI code.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeRole-ANSI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeRole-ANSI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeRole-ANSI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ColorThemeUtil::ANSI>

L<ColorTheme>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
