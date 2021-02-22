package BorderStyle::Test::Labeled;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-06'; # DATE
our $DIST = 'BorderStyleBase'; # DIST
our $VERSION = '0.009'; # VERSION

use strict;
use warnings;
use utf8;

use parent 'BorderStyleBase';

our %BORDER = (
    v => 2,
    summary => 'A border style that uses labeled characters as described in specification, to show which character goes where',
    chars => [                                     # y
        # 0    1    2    3    4    5    6    7     <-- x
        ['A', 'B', 'C', 'D'],                      # 0
        ['E', 'F', 'G'],                           # 1
        ['H', 'I', 'J', 'K', 'a', 'b'],            # 2
        ['L', 'M', 'N'],                           # 3
        ['O', 'P', 'Q', 'R', 'e', 'f', 'g', 'h'],  # 4
        ['S', 'T', 'U', 'V'],                      # 5

        ['Ȧ', 'Ḃ', 'Ċ', 'Ḋ'], # 6
        ['Ṣ', 'Ṭ', 'Ụ', 'Ṿ'], # 7
    ],
    utf8 => 1,
);

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Test::Labeled

=head1 VERSION

This document describes version 0.009 of BorderStyle::Test::Labeled (from Perl distribution BorderStyleBase), released on 2021-02-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyleBase>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyleBase>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-BorderStyleBase/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
