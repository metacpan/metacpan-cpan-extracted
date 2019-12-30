package Bencher::Scenario::LocaleTextDomainIfEnv::__;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-26'; # DATE
our $DIST = 'Bencher-Scenarios-LocaleTextDomainIfEnv'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark __()',

    modules => {
        # minimum versions
        #'Getopt::Long::EvenLess' => {version=>'0.10'},
    },

    participants => [
        {code_template=>'package P1; use Locale::TextDomain;              __("foo") for 1..1000'},
        {code_template=>'package P2; use Locale::TextDomain::IfEnv;       __("foo") for 1..1000'},
        {code_template=>'package P3; use Locale::TextDomain::UTF8;        __("foo") for 1..1000'},
        {code_template=>'package P4; use Locale::TextDomain::UTF8::IfEnv; __("foo") for 1..1000'},
    ],
};

1;
# ABSTRACT: Benchmark __()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LocaleTextDomainIfEnv::__ - Benchmark __()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::LocaleTextDomainIfEnv::__ (from Perl distribution Bencher-Scenarios-LocaleTextDomainIfEnv), released on 2019-12-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LocaleTextDomainIfEnv::__

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * package P1; use Locale::TextDomain;              __("foo") for 1 (perl_code)

Code template:

 package P1; use Locale::TextDomain;              __("foo") for 1..1000



=item * package P2; use Locale::TextDomain::IfEnv;       __("foo") for 1 (perl_code)

Code template:

 package P2; use Locale::TextDomain::IfEnv;       __("foo") for 1..1000



=item * package P3; use Locale::TextDomain::UTF8;        __("foo") for 1 (perl_code)

Code template:

 package P3; use Locale::TextDomain::UTF8;        __("foo") for 1..1000



=item * package P4; use Locale::TextDomain::UTF8::IfEnv; __("foo") for 1 (perl_code)

Code template:

 package P4; use Locale::TextDomain::UTF8::IfEnv; __("foo") for 1..1000



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m LocaleTextDomainIfEnv::__ >>):

 #table1#
 +------------------------------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                                                      | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------------------------------------+-----------+-----------+------------+---------+---------+
 | package P3; use Locale::TextDomain::UTF8;        __("foo") for 1 |     560   | 1.8       |     1      |   2e-06 |      20 |
 | package P1; use Locale::TextDomain;              __("foo") for 1 |     566   | 1.77      |     1.01   | 7.5e-07 |      20 |
 | package P4; use Locale::TextDomain::UTF8::IfEnv; __("foo") for 1 |   12700   | 0.0788    |    22.7    | 2.7e-08 |      20 |
 | package P2; use Locale::TextDomain::IfEnv;       __("foo") for 1 |   12684.8 | 0.0788347 |    22.7093 | 1.2e-11 |      20 |
 +------------------------------------------------------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LocaleTextDomainIfEnv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LocaleTextDomainIfEnv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LocaleTextDomainIfEnv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
