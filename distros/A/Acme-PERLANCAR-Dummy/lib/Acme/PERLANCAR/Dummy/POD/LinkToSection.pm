package Acme::PERLANCAR::Dummy::POD::LinkToSection;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-26'; # DATE
our $DIST = 'Acme-PERLANCAR-Dummy'; # DIST
our $VERSION = '0.011'; # VERSION

1;
# ABSTRACT: Testing POD section links

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::Dummy::POD::LinkToSection - Testing POD section links

=head1 VERSION

This document describes version 0.011 of Acme::PERLANCAR::Dummy::POD::LinkToSection (from Perl distribution Acme-PERLANCAR-Dummy), released on 2021-07-26.

=head1 LINK TARGETS

=head2 Subheading 1

This is subheading 1.

Paragraph 2.

Paragraph 3.

Paragraph 4.

Paragraph 5.

Paragraph 6.

Paragraph 7.

Paragraph 8.

Paragraph 9.

Paragraph 10.

Paragraph 11.

Paragraph 12.

Paragraph 13.

Paragraph 14.

Paragraph 15.

=head2 Subheading 2

This is subheading 2.

Paragraph 2.

Paragraph 3.

Paragraph 4.

Paragraph 5.

Paragraph 6.

Paragraph 7.

Paragraph 8.

Paragraph 9.

Paragraph 10.

Paragraph 11.

Paragraph 12.

Paragraph 13.

Paragraph 14.

Paragraph 15.

=head2 L<Foo::Bar>

This is subheading 2.

Paragraph 2.

Paragraph 3.

Paragraph 4.

Paragraph 5.

Paragraph 6.

Paragraph 7.

Paragraph 8.

Paragraph 9.

Paragraph 10.

Paragraph 11.

Paragraph 12.

Paragraph 13.

Paragraph 14.

Paragraph 15.

=head2 List items

=over

=item * Baz

This is list item 1.

Paragraph 2.

Paragraph 3.

Paragraph 4.

Paragraph 5.

Paragraph 6.

Paragraph 7.

Paragraph 8.

Paragraph 9.

Paragraph 10.

Paragraph 11.

Paragraph 12.

Paragraph 13.

Paragraph 14.

Paragraph 15.

=item * Qux

This is list item 2.

Paragraph 2.

Paragraph 3.

Paragraph 4.

Paragraph 5.

Paragraph 6.

Paragraph 7.

Paragraph 8.

Paragraph 9.

Paragraph 10.

Paragraph 11.

Paragraph 12.

Paragraph 13.

Paragraph 14.

Paragraph 15.

=item * L<Quux::Corge>

This is list item 3.

Paragraph 2.

Paragraph 3.

Paragraph 4.

Paragraph 5.

Paragraph 6.

Paragraph 7.

Paragraph 8.

Paragraph 9.

Paragraph 10.

Paragraph 11.

Paragraph 12.

Paragraph 13.

Paragraph 14.

Paragraph 15.

=back

=head1 SOME SECTION

This is a filler section.

Paragraph 2.

Paragraph 3.

Paragraph 4.

Paragraph 5.

Paragraph 6.

Paragraph 7.

Paragraph 8.

Paragraph 9.

Paragraph 10.

Paragraph 11.

Paragraph 12.

Paragraph 13.

Paragraph 14.

Paragraph 15.

=head1 LINKS

Link to section Subheading 1 (a =head2): L</Subheading 1>.

Link to section Subheading 2 (a =head2): L</Subheading 2>.

Link to section Foo::Bar (a =head2 but text is inside a module link: =head2 LE<lt>Foo::BarE<gt>):
L</Foo::Bar>. On MetaCPAN, it works.

Link to section Baz (an =item): L</Baz>. On MetaCPAN, it sometimes works but
sometimes does not.

Link to section Baz (an =item but text is inside a link: =item *
LE<lt>Quux::CorgeE<gt>): L</Quux::Corge>. On MetaCPAN, it sometimes works but
sometimes does not.

=head1 TODO

Link to section with some text inside link, e.g.:

 =head2 Some L<text>

Link to section with other kind of links or links with text:

 =head2 Some L<text|https://example.org>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-Dummy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-Dummy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PERLANCAR-Dummy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
