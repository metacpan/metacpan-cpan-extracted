package Acme::CPANAuthors::CPAN::Streaks::WeeklyReleases;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-25'; # DATE
our $DIST = 'Acme-CPANAuthorsBundle-CPAN-Streaks'; # DIST
our $VERSION = '20231120.0'; # VERSION

use Acme::CPANAuthors::Register (
    'PERLANCAR' => '',
    'ETHER' => '',
    'PEVANS' => '',
    'JDEGUEST' => '',
    'LEONT' => '',
    'SKIM' => '',
    'JIMAVERA' => '',
    'JRM' => '',
    'KIMOTO' => '',
    'LICHTKIND' => '',
    'PRBRENAN' => '',
    'JJATRIA' => '',
    'BDFOY' => '',
    'DCANTRELL' => '',
    'DERF' => '',
    'SVW' => '',
    'ZMUGHAL' => '',
    'UTASHIRO' => '',
    'ABELTJE' => '',
    'BORISD' => '',
    'DANKOGAI' => '',
    'DORNER' => '',
    'DRCLAW' => '',
    'GDT' => '',
    'GENE' => '',
    'HOCHSTEN' => '',
    'KAZEBURO' => '',
    'LNATION' => '',
    'NHORNE' => '',
    'RKAPL' => '',
    'TEAM' => '',
    'TONYC' => '',
    'TOSHIOITO' => '',
    'VVELOX' => '',
    'AJNN' => '',
    'BIGFOOT' => '',
    'SIMCOP' => '',
    'WHOM' => '',
    'BORISV' => '',
    'BPS' => '',
    'CGPAN' => '',
    'DANBERR' => '',
    'DART' => '',
    'DCONWAY' => '',
    'DDICK' => '',
    'DDUMONT' => '',
    'DUMB' => '',
    'EINHVERFR' => '',
    'GAHAYES' => '',
    'GNUSTAVO' => '',
    'GRAY' => '',
    'GWILLIAMS' => '',
    'JKEENAN' => '',
    'JMASLAK' => '',
    'LEEJO' => '',
    'MBARBON' => '',
    'MIKKOI' => '',
    'OLIVER' => '',
    'PJACKLAM' => '',
    'RBAIRWELL' => '',
    'RKELSCH' => '',
    'SGRAY' => '',
    'SHOGO' => '',
    'STRAKA' => '',
    'TROTH' => '',
    'TURNERJW' => '',
    'YANGAK' => '',
    'YANICK' => '',
    'ETJ' => '',
    'EXIFTOOL' => '',
    'FSEITZ' => '',
    'JV' => '',
);

1;
# ABSTRACT: Authors with ongoing weekly releases streak (do a release every week)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::Streaks::WeeklyReleases - Authors with ongoing weekly releases streak (do a release every week)

=head1 VERSION

This document describes version 20231120.0 of Acme::CPANAuthors::CPAN::Streaks::WeeklyReleases (from Perl distribution Acme-CPANAuthorsBundle-CPAN-Streaks), released on 2023-11-25.

=head1 SYNOPSIS

=head1 DESCRIPTION

Current standings (as of 2023-11-20, produced by L<cpan-streaks>):

 % cpan-streaks calculate weekly-releases
 | author    | len | start_date | status      |
 |-----------+-----+------------+-------------|
 | PERLANCAR | 483 | 2014-08-24 | ongoing     |
 | ETHER     |  87 | 2022-03-20 | might-break |
 | PEVANS    |  20 | 2023-07-02 | might-break |
 | JDEGUEST  |  10 | 2023-09-17 | ongoing     |
 | LEONT     |   8 | 2023-09-24 | might-break |
 | SKIM      |   6 | 2023-10-15 | ongoing     |
 | JIMAVERA  |   5 | 2023-10-15 | might-break |
 | JRM       |   4 | 2023-10-22 | might-break |
 | KIMOTO    |   4 | 2023-10-22 | might-break |
 | LICHTKIND |   4 | 2023-10-22 | might-break |
 | PRBRENAN  |   4 | 2023-10-22 | might-break |
 | JJATRIA   |   4 | 2023-10-29 | ongoing     |
 | BDFOY     |   3 | 2023-10-29 | might-break |
 | DCANTRELL |   3 | 2023-10-29 | might-break |
 | DERF      |   3 | 2023-10-29 | might-break |
 | SVW       |   3 | 2023-10-29 | might-break |
 | ZMUGHAL   |   3 | 2023-10-29 | might-break |
 | UTASHIRO  |   3 | 2023-11-05 | ongoing     |
 | ABELTJE   |   2 | 2023-11-05 | might-break |
 | BORISD    |   2 | 2023-11-05 | might-break |
 | DANKOGAI  |   2 | 2023-11-05 | might-break |
 | DORNER    |   2 | 2023-11-05 | might-break |
 | DRCLAW    |   2 | 2023-11-05 | might-break |
 | GDT       |   2 | 2023-11-05 | might-break |
 | GENE      |   2 | 2023-11-05 | might-break |
 | HOCHSTEN  |   2 | 2023-11-05 | might-break |
 | KAZEBURO  |   2 | 2023-11-05 | might-break |
 | LNATION   |   2 | 2023-11-05 | might-break |
 | NHORNE    |   2 | 2023-11-05 | might-break |
 | RKAPL     |   2 | 2023-11-05 | might-break |
 | TEAM      |   2 | 2023-11-05 | might-break |
 | TONYC     |   2 | 2023-11-05 | might-break |
 | TOSHIOITO |   2 | 2023-11-05 | might-break |
 | VVELOX    |   2 | 2023-11-05 | might-break |
 | AJNN      |   2 | 2023-11-12 | ongoing     |
 | BIGFOOT   |   2 | 2023-11-12 | ongoing     |
 | SIMCOP    |   2 | 2023-11-12 | ongoing     |
 | WHOM      |   2 | 2023-11-12 | ongoing     |
 | BORISV    |   1 | 2023-11-12 | might-break |
 | BPS       |   1 | 2023-11-12 | might-break |
 | CGPAN     |   1 | 2023-11-12 | might-break |
 | DANBERR   |   1 | 2023-11-12 | might-break |
 | DART      |   1 | 2023-11-12 | might-break |
 | DCONWAY   |   1 | 2023-11-12 | might-break |
 | DDICK     |   1 | 2023-11-12 | might-break |
 | DDUMONT   |   1 | 2023-11-12 | might-break |
 | DUMB      |   1 | 2023-11-12 | might-break |
 | EINHVERFR |   1 | 2023-11-12 | might-break |
 | GAHAYES   |   1 | 2023-11-12 | might-break |
 | GNUSTAVO  |   1 | 2023-11-12 | might-break |
 | GRAY      |   1 | 2023-11-12 | might-break |
 | GWILLIAMS |   1 | 2023-11-12 | might-break |
 | JKEENAN   |   1 | 2023-11-12 | might-break |
 | JMASLAK   |   1 | 2023-11-12 | might-break |
 | LEEJO     |   1 | 2023-11-12 | might-break |
 | MBARBON   |   1 | 2023-11-12 | might-break |
 | MIKKOI    |   1 | 2023-11-12 | might-break |
 | OLIVER    |   1 | 2023-11-12 | might-break |
 | PJACKLAM  |   1 | 2023-11-12 | might-break |
 | RBAIRWELL |   1 | 2023-11-12 | might-break |
 | RKELSCH   |   1 | 2023-11-12 | might-break |
 | SGRAY     |   1 | 2023-11-12 | might-break |
 | SHOGO     |   1 | 2023-11-12 | might-break |
 | STRAKA    |   1 | 2023-11-12 | might-break |
 | TROTH     |   1 | 2023-11-12 | might-break |
 | TURNERJW  |   1 | 2023-11-12 | might-break |
 | YANGAK    |   1 | 2023-11-12 | might-break |
 | YANICK    |   1 | 2023-11-12 | might-break |
 | ETJ       |   1 | 2023-11-19 | ongoing     |
 | EXIFTOOL  |   1 | 2023-11-19 | ongoing     |
 | FSEITZ    |   1 | 2023-11-19 | ongoing     |
 | JV        |   1 | 2023-11-19 | ongoing     |

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
