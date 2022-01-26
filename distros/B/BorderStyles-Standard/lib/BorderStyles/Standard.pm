package BorderStyles::Standard;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-26'; # DATE
our $DIST = 'BorderStyles-Standard'; # DIST
our $VERSION = '0.011'; # VERSION

1;
# ABSTRACT: A standard collection of border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyles::Standard - A standard collection of border styles

=head1 VERSION

This document describes version 0.011 of BorderStyles::Standard (from Perl distribution BorderStyles-Standard), released on 2022-01-26.

=head1 BORDER STYLES

=over

=item * L<BorderStyle::ASCII::None>

No borders, but data row separator is still drawn using dashes.

=item * L<BorderStyle::ASCII::SingleLine>

Single line border with ASCII characters.

=item * L<BorderStyle::ASCII::SingleLineDoubleAfterHeader>

Just like ASCII::SingleLine but uses double line to separate header row and first data row.

=item * L<BorderStyle::ASCII::SingleLineHorizontalOnly>

Single line border with ASCII characters, horizontal only.

=item * L<BorderStyle::ASCII::SingleLineInnerOnly>

Single line border with ASCII characters, between columns only.

=item * L<BorderStyle::ASCII::SingleLineOuterOnly>

Single line border with ASCII characters, outer borders only.

=item * L<BorderStyle::ASCII::SingleLineVerticalOnly>

Single line border with ASCII characters, vertical only.

=item * L<BorderStyle::ASCII::Space>

Space as borders, but data row separator is still drawn using dashes.

=item * L<BorderStyle::ASCII::SpaceInnerOnly>

No borders, but columns are still separated using spaces and data row separator is still drawn using dashes.

=item * L<BorderStyle::BoxChar::None>

No borders, but data row separator is still drawn using horizontal line.

=item * L<BorderStyle::BoxChar::SingleLine>

Single line border with box-drawing characters.

=item * L<BorderStyle::BoxChar::SingleLineHorizontalOnly>

Single line border with box-drawing characters, horizontal only.

=item * L<BorderStyle::BoxChar::SingleLineInnerOnly>

Single line border with box-drawing characters, between columns only.

=item * L<BorderStyle::BoxChar::SingleLineOuterOnly>

Single line border with box-drawing characters, outer borders only.

=item * L<BorderStyle::BoxChar::SingleLineVerticalOnly>

Single line border with box-drawing characters, vertical only.

=item * L<BorderStyle::BoxChar::Space>

Space as borders, but data row separator is still drawn using horizontal line.

=item * L<BorderStyle::BoxChar::SpaceInnerOnly>

No borders, but columns are still separated using spaces and data row separator is still drawn using horizontal line.

=item * L<BorderStyle::UTF8::Brick>

Single-line, bold on bottom right to give illusion of depth.

=item * L<BorderStyle::UTF8::BrickOuterOnly>

Single-line (outer only), bold on bottom right to give illusion of depth.

=item * L<BorderStyle::UTF8::DoubleLine>

Double-line border with UTF8 characters.

=item * L<BorderStyle::UTF8::None>

No borders, but data row separator is still drawn using horizontal line.

=item * L<BorderStyle::UTF8::SingleLine>

Single-line border with UTF8 characters.

=item * L<BorderStyle::UTF8::SingleLineBold>

Bold single-line border with UTF8 characters.

=item * L<BorderStyle::UTF8::SingleLineBoldHeader>

Single-line border (header box bold) with UTF8 characters.

=item * L<BorderStyle::UTF8::SingleLineCurved>

Single-line border with UTF8 characters, curved edges.

=item * L<BorderStyle::UTF8::SingleLineDoubleAfterHeader>

Just like UTF8::SingleLine but uses double line to separate header row and first data row.

=item * L<BorderStyle::UTF8::SingleLineHorizontalOnly>

Single line border with box-drawing characters, horizontal only.

=item * L<BorderStyle::UTF8::SingleLineInnerOnly>

Single line border with UTF8 characters, between columns only.

=item * L<BorderStyle::UTF8::SingleLineOuterOnly>

Single line border with UTF8 characters, outer borders only.

=item * L<BorderStyle::UTF8::SingleLineVerticalOnly>

Single line border with UTF8 characters, vertical only.

=item * L<BorderStyle::UTF8::Space>

Space as borders, but data row separator is still drawn using horizontal line.

=item * L<BorderStyle::UTF8::SpaceInnerOnly>

No borders, but columns are still separated using spaces and data row separator is still drawn using horizontal line.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyles-Standard>.

=head1 SEE ALSO

L<BorderStyle> - specification

L<App::BorderStyleUtils> - CLIs

L<Text::Table::TinyBorderStyle>, L<Text::ANSITable> - some table renderers that can use border styles

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
