package Acme::CPANAuthors::CPAN::Streaks::DailyReleases;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-25'; # DATE
our $DIST = 'Acme-CPANAuthorsBundle-CPAN-Streaks'; # DIST
our $VERSION = '20231120.0'; # VERSION

use Acme::CPANAuthors::Register (
    'PERLANCAR' => '',
    'SKIM' => '',
    'AJNN' => '',
    'BIGFOOT' => '',
    'UTASHIRO' => '',
    'WHOM' => '',
    'ETJ' => '',
    'EXIFTOOL' => '',
    'FSEITZ' => '',
    'JDEGUEST' => '',
    'JJATRIA' => '',
    'JV' => '',
    'SIMCOP' => '',
);

1;
# ABSTRACT: Authors with ongoing daily releases streak (do a release everyday)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::Streaks::DailyReleases - Authors with ongoing daily releases streak (do a release everyday)

=head1 VERSION

This document describes version 20231120.0 of Acme::CPANAuthors::CPAN::Streaks::DailyReleases (from Perl distribution Acme-CPANAuthorsBundle-CPAN-Streaks), released on 2023-11-25.

=head1 SYNOPSIS

=head1 DESCRIPTION

Current standings (as of 2023-11-20, produced by L<cpan-streaks>):

 % cpan-streaks calculate daily-releases
 | author    |  len | start_date | status      |
 |-----------+------+------------+-------------|
 | PERLANCAR | 1649 | 2019-05-17 | ongoing     |
 | SKIM      |    3 | 2023-11-17 | might-break |
 | AJNN      |    2 | 2023-11-18 | might-break |
 | BIGFOOT   |    2 | 2023-11-18 | might-break |
 | UTASHIRO  |    2 | 2023-11-18 | might-break |
 | WHOM      |    2 | 2023-11-18 | might-break |
 | ETJ       |    1 | 2023-11-19 | might-break |
 | EXIFTOOL  |    1 | 2023-11-19 | might-break |
 | FSEITZ    |    1 | 2023-11-19 | might-break |
 | JDEGUEST  |    1 | 2023-11-19 | might-break |
 | JJATRIA   |    1 | 2023-11-19 | might-break |
 | JV        |    1 | 2023-11-19 | might-break |
 | SIMCOP    |    1 | 2023-11-19 | might-break |

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthorsBundle-CPAN-Streaks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthorsBundle-CPAN-Streaks>.

=head1 SEE ALSO

L<Acme::CPANAuthors>

CPAN Regulars Boards, L<http://cpan.io/board/once-a/>, which as of this writing,
has some input data missing and thus produces some incorrect results.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthorsBundle-CPAN-Streaks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
