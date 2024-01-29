package Acme::CPANAuthors::CPAN::Streaks::DailyReleases::Current;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-01'; # DATE
our $DIST = 'Acme-CPANAuthorsBundle-CPAN-Streaks'; # DIST
our $VERSION = '20240101.0'; # VERSION

use Acme::CPANAuthors::Register (
    'PERLANCAR' => '',
    'BINGOS' => '',
    'BODOLFO' => '',
    'MRDVT' => '',
    'JGNI' => '',
    'BPSCHUCK' => '',
    'ETHER' => '',
    'GBROWN' => '',
    'JV' => '',
    'MIKKOI' => '',
    'PEVANS' => '',
    'SKAJI' => '',
    'UTASHIRO' => '',
    'VKON' => '',
    'JMATES' => '',
);


1;
# ABSTRACT: Authors with ongoing daily releases streak (do a release everyday)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::Streaks::DailyReleases::Current - Authors with ongoing daily releases streak (do a release everyday)

=head1 VERSION

This document describes version 20240101.0 of Acme::CPANAuthors::CPAN::Streaks::DailyReleases::Current (from Perl distribution Acme-CPANAuthorsBundle-CPAN-Streaks), released on 2024-01-01.

=head1 SYNOPSIS

=head1 DESCRIPTION

Current standings (as of 2024-01-01, produced by L<cpan-streaks>):

  +-----------+------+------------+-------------+
  | author    |  len | start_date | status      |
  +-----------+------+------------+-------------+
  | PERLANCAR | 1691 | 2019-05-17 | ongoing     |
  | BINGOS    |    2 | 2023-12-30 | might-break |
  | BODOLFO   |    2 | 2023-12-30 | might-break |
  | MRDVT     |    2 | 2023-12-30 | might-break |
  | JGNI      |    2 | 2023-12-31 | ongoing     |
  | BPSCHUCK  |    1 | 2023-12-31 | might-break |
  | ETHER     |    1 | 2023-12-31 | might-break |
  | GBROWN    |    1 | 2023-12-31 | might-break |
  | JV        |    1 | 2023-12-31 | might-break |
  | MIKKOI    |    1 | 2023-12-31 | might-break |
  | PEVANS    |    1 | 2023-12-31 | might-break |
  | SKAJI     |    1 | 2023-12-31 | might-break |
  | UTASHIRO  |    1 | 2023-12-31 | might-break |
  | VKON      |    1 | 2023-12-31 | might-break |
  | JMATES    |    1 | 2024-01-01 | ongoing     |
  +-----------+------+------------+-------------+

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

This software is copyright (c) 2024, 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthorsBundle-CPAN-Streaks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
