package Acme::CPANAuthors::CPAN::Streaks::DailyReleases::AllTime;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Acme-CPANAuthorsBundle-CPAN-Streaks'; # DIST
our $VERSION = '20240506.0'; # VERSION

use Acme::CPANAuthors::Register (
    'PERLANCAR' => '',
    'MANWAR' => '',
    'BARBIE' => '',
    'SKIM' => '',
    'NEILB' => '',
    'IVANWILLS' => '',
    'KENTNL' => '',
    'ETHER' => '',
    'RENEEB' => '',
    'CSSON' => '',
    'INGY' => '',
    'PLICEASE' => '',
    'ZOFFIX' => '',
    'SCHUBIGER' => '',
    'TOBYINK' => '',
    'WOLLMERS' => '',
    'LNATION' => '',
    'BKB' => '',
);


1;
# ABSTRACT: Authors with all-time daily releases streak (do a release everyday)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::Streaks::DailyReleases::AllTime - Authors with all-time daily releases streak (do a release everyday)

=head1 VERSION

This document describes version 20240506.0 of Acme::CPANAuthors::CPAN::Streaks::DailyReleases::AllTime (from Perl distribution Acme-CPANAuthorsBundle-CPAN-Streaks), released on 2024-05-06.

=head1 SYNOPSIS

=head1 DESCRIPTION

Current standings (as of 2024-05-06, produced by L<cpan-streaks>, only streaks with length of at least 20 are included):

  +-----------+------+------------+------------+---------+
  | author    |  len | start_date | end_date   | status  |
  +-----------+------+------------+------------+---------+
  | PERLANCAR | 1737 | 2019-05-17 | 2024-02-16 | broken  |
  | MANWAR    | 1027 | 2014-10-28 | 2017-08-19 | broken  |
  | MANWAR    |  621 | 2017-08-21 | 2019-05-03 | broken  |
  | BARBIE    |  370 | 2014-03-19 | 2015-03-23 | broken  |
  | MANWAR    |  182 | 2019-05-05 | 2019-11-02 | broken  |
  | SKIM      |  145 | 2014-10-31 | 2015-03-24 | broken  |
  | NEILB     |  111 | 2014-03-20 | 2014-07-08 | broken  |
  | IVANWILLS |  102 | 2015-05-17 | 2015-08-26 | broken  |
  | KENTNL    |  101 | 2014-07-12 | 2014-10-20 | broken  |
  | PERLANCAR |   81 | 2016-12-20 | 2017-03-10 | broken  |
  | ETHER     |   77 | 2014-06-01 | 2014-08-16 | broken  |
  | RENEEB    |   76 | 2018-12-31 | 2019-03-16 | broken  |
  | PERLANCAR |   74 | 2024-02-23 |            | ongoing |
  | CSSON     |   55 | 2014-12-30 | 2015-02-22 | broken  |
  | INGY      |   47 | 2014-07-21 | 2014-09-05 | broken  |
  | RENEEB    |   44 | 2014-11-27 | 2015-01-09 | broken  |
  | SKIM      |   35 | 2014-08-04 | 2014-09-07 | broken  |
  | PLICEASE  |   32 | 2017-07-05 | 2017-08-05 | broken  |
  | CSSON     |   28 | 2014-08-30 | 2014-09-26 | broken  |
  | NEILB     |   28 | 2015-10-19 | 2015-11-15 | broken  |
  | ZOFFIX    |   27 | 2008-03-01 | 2008-03-27 | broken  |
  | SCHUBIGER |   26 | 2004-01-11 | 2004-02-05 | broken  |
  | TOBYINK   |   26 | 2022-06-19 | 2022-07-14 | broken  |
  | ETHER     |   25 | 2014-05-06 | 2014-05-30 | broken  |
  | PERLANCAR |   25 | 2014-12-24 | 2015-01-17 | broken  |
  | PERLANCAR |   23 | 2016-01-02 | 2016-01-24 | broken  |
  | WOLLMERS  |   22 | 2014-07-26 | 2014-08-16 | broken  |
  | LNATION   |   21 | 2017-03-04 | 2017-03-24 | broken  |
  | BKB       |   21 | 2020-12-07 | 2020-12-27 | broken  |
  | PERLANCAR |   20 | 2016-02-02 | 2016-02-21 | broken  |
  +-----------+------+------------+------------+---------+

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
