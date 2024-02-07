package Acme::CPANAuthors::CPAN::Streaks::DailyDistributions::AllTime;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-01'; # DATE
our $DIST = 'Acme-CPANAuthorsBundle-CPAN-Streaks'; # DIST
our $VERSION = '20240201.0'; # VERSION

use Acme::CPANAuthors::Register (
    'PERLANCAR' => '',
    'ZOFFIX' => '',
    'CSSON' => '',
    'MARCEL' => '',
    'RJBS' => '',
    'NEILB' => '',
    'SHARYANTO' => '',
);


1;
# ABSTRACT: Authors with all-time daily distributions streak (release a new [for them] distribution everyday)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::Streaks::DailyDistributions::AllTime - Authors with all-time daily distributions streak (release a new [for them] distribution everyday)

=head1 VERSION

This document describes version 20240201.0 of Acme::CPANAuthors::CPAN::Streaks::DailyDistributions::AllTime (from Perl distribution Acme-CPANAuthorsBundle-CPAN-Streaks), released on 2024-02-01.

=head1 SYNOPSIS

=head1 DESCRIPTION

Current standings (as of 2024-02-01, produced by L<cpan-streaks>, only streaks with length of at least 6 are included):

  +-----------+-----+------------+------------+---------+
  | author    | len | start_date | end_date   | status  |
  +-----------+-----+------------+------------+---------+
  | PERLANCAR |  24 | 2024-01-09 |            | ongoing |
  | ZOFFIX    |  23 | 2008-03-05 | 2008-03-27 | broken  |
  | CSSON     |  16 | 2014-12-31 | 2015-01-15 | broken  |
  | PERLANCAR |  16 | 2017-08-01 | 2017-08-16 | broken  |
  | ZOFFIX    |  11 | 2008-07-27 | 2008-08-06 | broken  |
  | PERLANCAR |  11 | 2014-11-27 | 2014-12-07 | broken  |
  | PERLANCAR |  10 | 2015-01-01 | 2015-01-10 | broken  |
  | PERLANCAR |   9 | 2016-05-16 | 2016-05-24 | broken  |
  | PERLANCAR |   9 | 2020-06-03 | 2020-06-11 | broken  |
  | ZOFFIX    |   7 | 2008-11-01 | 2008-11-07 | broken  |
  | PERLANCAR |   7 | 2014-12-24 | 2014-12-30 | broken  |
  | PERLANCAR |   7 | 2016-03-07 | 2016-03-13 | broken  |
  | PERLANCAR |   7 | 2020-10-16 | 2020-10-22 | broken  |
  | MARCEL    |   6 | 2007-11-07 | 2007-11-12 | broken  |
  | RJBS      |   6 | 2008-10-02 | 2008-10-07 | broken  |
  | NEILB     |   6 | 2014-06-08 | 2014-06-13 | broken  |
  | SHARYANTO |   6 | 2014-06-22 | 2014-06-27 | broken  |
  | NEILB     |   6 | 2014-06-27 | 2014-07-02 | broken  |
  | PERLANCAR |   6 | 2015-03-21 | 2015-03-26 | broken  |
  | PERLANCAR |   6 | 2015-03-31 | 2015-04-05 | broken  |
  | PERLANCAR |   6 | 2016-01-17 | 2016-01-22 | broken  |
  | PERLANCAR |   6 | 2016-02-13 | 2016-02-18 | broken  |
  | PERLANCAR |   6 | 2016-03-19 | 2016-03-24 | broken  |
  | PERLANCAR |   6 | 2016-07-08 | 2016-07-13 | broken  |
  | PERLANCAR |   6 | 2017-06-23 | 2017-06-28 | broken  |
  | PERLANCAR |   6 | 2018-01-12 | 2018-01-17 | broken  |
  | PERLANCAR |   6 | 2018-06-22 | 2018-06-27 | broken  |
  | PERLANCAR |   6 | 2020-04-14 | 2020-04-19 | broken  |
  | PERLANCAR |   6 | 2020-08-18 | 2020-08-23 | broken  |
  | PERLANCAR |   6 | 2020-10-01 | 2020-10-06 | broken  |
  | PERLANCAR |   6 | 2021-05-18 | 2021-05-23 | broken  |
  +-----------+-----+------------+------------+---------+

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
