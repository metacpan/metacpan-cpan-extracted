package BorderStyle::Test::Labeled;

use strict;
use warnings;
use utf8;

use parent 'BorderStyleBase';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-24'; # DATE
our $DIST = 'BorderStyleBase'; # DIST
our $VERSION = '0.010'; # VERSION

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

This document describes version 0.010 of BorderStyle::Test::Labeled (from Perl distribution BorderStyleBase), released on 2022-01-24.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyleBase>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyleBase>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyleBase>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
