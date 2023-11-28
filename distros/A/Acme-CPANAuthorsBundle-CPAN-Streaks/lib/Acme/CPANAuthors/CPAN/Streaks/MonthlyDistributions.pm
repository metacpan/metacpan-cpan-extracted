package Acme::CPANAuthors::CPAN::Streaks::MonthlyDistributions;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-25'; # DATE
our $DIST = 'Acme-CPANAuthorsBundle-CPAN-Streaks'; # DIST
our $VERSION = '20231120.0'; # VERSION

use Acme::CPANAuthors::Register (
    'PERLANCAR' => '',
    'SKIM' => '',
    'TIMLEGGE' => '',
    'LEONT' => '',
    'PEVANS' => '',
    'DJERIUS' => '',
    'GARU' => '',
    'DART' => '',
    'ABRAXXA' => '',
    'FKENTO' => '',
    'MERKYS' => '',
    'NERDVANA' => '',
    'ZHMYLOVE' => '',
    'JJATRIA' => '',
    'PRBRENAN' => '',
    'ABALAMA' => '',
    'ABELTJE' => '',
    'AKHUETTEL' => '',
    'BRAINBUZ' => '',
    'DRCLAW' => '',
    'GEEKRUTH' => '',
    'GRYPHON' => '',
    'GSG' => '',
    'HAARG' => '',
    'HOCHSTEN' => '',
    'JMATES' => '',
    'LEMBARK' => '',
    'LION' => '',
    'NEILB' => '',
    'NICOMEN' => '',
    'PERLSRVDE' => '',
    'REFECO' => '',
    'RENEEB' => '',
    'SANKO' => '',
    'SIMBABQUE' => '',
    'SISYPHUS' => '',
    'SPRAGL' => '',
    'SUKRIA' => '',
    'SUMAN' => '',
    'TEODESIAN' => '',
    'YANGAK' => '',
    'BIGFOOT' => '',
    'DCHURCH' => '',
    'DERF' => '',
    'DTUCKWELL' => '',
    'EINHVERFR' => '',
    'GENE' => '',
    'JOYREX' => '',
    'KIMOTO' => '',
    'LANCEW' => '',
    'LICHTKIND' => '',
    'RAWLEYFOW' => '',
    'RBAIRWELL' => '',
    'RRWO' => '',
    'SIMCOP' => '',
    'SVW' => '',
    'TROTH' => '',
    'VVELOX' => '',
    'YANICK' => '',
    'ZMUGHAL' => '',
);

1;
# ABSTRACT: Authors with ongoing monthly distributions streak (release a new [for them] distribution every month)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::Streaks::MonthlyDistributions - Authors with ongoing monthly distributions streak (release a new [for them] distribution every month)

=head1 VERSION

This document describes version 20231120.0 of Acme::CPANAuthors::CPAN::Streaks::MonthlyDistributions (from Perl distribution Acme-CPANAuthorsBundle-CPAN-Streaks), released on 2023-11-25.

=head1 SYNOPSIS

=head1 DESCRIPTION

Current standings (as of 2023-11-20, produced by L<cpan-streaks>):

 % cpan-streaks calculate monthly-distributions
 | author    | len | start_date | status      |
 |-----------+-----+------------+-------------|
 | PERLANCAR | 112 | 2014-08    | ongoing     |
 | SKIM      |   9 | 2023-03    | ongoing     |
 | TIMLEGGE  |   5 | 2023-06    | might-break |
 | LEONT     |   5 | 2023-07    | ongoing     |
 | PEVANS    |   4 | 2023-07    | might-break |
 | DJERIUS   |   3 | 2023-08    | might-break |
 | GARU      |   3 | 2023-08    | might-break |
 | DART      |   3 | 2023-09    | ongoing     |
 | ABRAXXA   |   2 | 2023-09    | might-break |
 | FKENTO    |   2 | 2023-09    | might-break |
 | MERKYS    |   2 | 2023-09    | might-break |
 | NERDVANA  |   2 | 2023-09    | might-break |
 | ZHMYLOVE  |   2 | 2023-09    | might-break |
 | JJATRIA   |   2 | 2023-10    | ongoing     |
 | PRBRENAN  |   2 | 2023-10    | ongoing     |
 | ABALAMA   |   1 | 2023-10    | might-break |
 | ABELTJE   |   1 | 2023-10    | might-break |
 | AKHUETTEL |   1 | 2023-10    | might-break |
 | BRAINBUZ  |   1 | 2023-10    | might-break |
 | DRCLAW    |   1 | 2023-10    | might-break |
 | GEEKRUTH  |   1 | 2023-10    | might-break |
 | GRYPHON   |   1 | 2023-10    | might-break |
 | GSG       |   1 | 2023-10    | might-break |
 | HAARG     |   1 | 2023-10    | might-break |
 | HOCHSTEN  |   1 | 2023-10    | might-break |
 | JMATES    |   1 | 2023-10    | might-break |
 | LEMBARK   |   1 | 2023-10    | might-break |
 | LION      |   1 | 2023-10    | might-break |
 | NEILB     |   1 | 2023-10    | might-break |
 | NICOMEN   |   1 | 2023-10    | might-break |
 | PERLSRVDE |   1 | 2023-10    | might-break |
 | REFECO    |   1 | 2023-10    | might-break |
 | RENEEB    |   1 | 2023-10    | might-break |
 | SANKO     |   1 | 2023-10    | might-break |
 | SIMBABQUE |   1 | 2023-10    | might-break |
 | SISYPHUS  |   1 | 2023-10    | might-break |
 | SPRAGL    |   1 | 2023-10    | might-break |
 | SUKRIA    |   1 | 2023-10    | might-break |
 | SUMAN     |   1 | 2023-10    | might-break |
 | TEODESIAN |   1 | 2023-10    | might-break |
 | YANGAK    |   1 | 2023-10    | might-break |
 | BIGFOOT   |   1 | 2023-11    | ongoing     |
 | DCHURCH   |   1 | 2023-11    | ongoing     |
 | DERF      |   1 | 2023-11    | ongoing     |
 | DTUCKWELL |   1 | 2023-11    | ongoing     |
 | EINHVERFR |   1 | 2023-11    | ongoing     |
 | GENE      |   1 | 2023-11    | ongoing     |
 | JOYREX    |   1 | 2023-11    | ongoing     |
 | KIMOTO    |   1 | 2023-11    | ongoing     |
 | LANCEW    |   1 | 2023-11    | ongoing     |
 | LICHTKIND |   1 | 2023-11    | ongoing     |
 | RAWLEYFOW |   1 | 2023-11    | ongoing     |
 | RBAIRWELL |   1 | 2023-11    | ongoing     |
 | RRWO      |   1 | 2023-11    | ongoing     |
 | SIMCOP    |   1 | 2023-11    | ongoing     |
 | SVW       |   1 | 2023-11    | ongoing     |
 | TROTH     |   1 | 2023-11    | ongoing     |
 | VVELOX    |   1 | 2023-11    | ongoing     |
 | YANICK    |   1 | 2023-11    | ongoing     |
 | ZMUGHAL   |   1 | 2023-11    | ongoing     |

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
