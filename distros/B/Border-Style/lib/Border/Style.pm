package Border::Style;

our $DATE = '2014-12-10'; # DATE
our $VERSION = '0.01'; # VERSION

1;
# ABSTRACT: Border style structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Border::Style - Border style structure

=head1 VERSION

This document describes version 0.01 of Border::Style (from Perl distribution Border-Style), released on 2014-12-10.

=head1 DESCRIPTION

This module specifies a structure for border styles. The distribution also comes
with utility routines and roles for managing border styles in applications.

=head1 SPECIFICATION

Border style is a L<DefHash> containing these keys: C<v>, C<name>, C<summary>,
C<utf8> (bool, set to true to indicate that characters are Unicode characters in
UTF8), C<chars> (array). Format for the characters in C<chars>:

 [
   [A, b, C, D],  # 0
   [E, F, G],     # 1
   [H, i, J, K],  # 2
   [L, M, N],     # 3
   [O, p, Q, R],  # 4
   [S, t, U, V],  # 5
 ]

 AbbbCbbbD        #0 Top border characters
 E   F   G        #1 Vertical separators for header row
 HiiiJiiiK        #2 Separator between header row and first data row
 L   M   N        #3 Vertical separators for data row
 OpppQpppR        #4 Separator between data rows
 L   M   N        #3
 StttUtttV        #5 Bottom border characters

A character can also be a coderef that will be called with C<< ($self, %args)
>>. Arguments in C<%args> contains information such as C<name>, C<y>, C<x>, C<n>
(how many times should character be repeated), etc.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Border-Style>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Border-Style>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Border-Style>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
