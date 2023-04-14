package Bencher::Scenario::String::PodQuote;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-String-PodQuote'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark String::PodQuote',
    participants => [
        {
            fcall_template => 'String::PodQuote::pod_escape(<text>)',
        },
    ],
    datasets => [
        {

            name => 'short', args => {text=>'This is <, >, C<=>, =, /, and |.'},
        },
        {
            name => 'long', args => {text=><<'_',},
Normally you will only need to do this in an application, not in modules. One
piece of advice is to allow user to change the level without her having to
modify the source code, for example via environment variable and/or < command-line
option. An application framework like L<Perinci::CmdLine> will already take care
of this for you, so you don't need to do C<set_level> manually at all.
_

        },
    ],
};

1;
# ABSTRACT: Benchmark String::PodQuote

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::String::PodQuote - Benchmark String::PodQuote

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::String::PodQuote (from Perl distribution Bencher-Scenario-String-PodQuote), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m String::PodQuote

To run module startup overhead benchmark:

 % bencher --module-startup -m String::PodQuote

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::PodQuote> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::PodQuote::pod_escape (perl_code)

Function call template:

 String::PodQuote::pod_escape(<text>)



=back

=head1 BENCHMARK DATASETS

=over

=item * short

=item * long

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with C<< bencher -m String::PodQuote --env-hashes-json '[{"PERL5OPT":"-Iarchive/String-PodQuote-0.002/lib"},{"PERL5OPT":"-Iarchive/String-PodQuote-0.003/lib"}]' >>:

 #table1#
 +---------+----------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset | env                                          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------+----------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | long    | PERL5OPT=-Iarchive/String-PodQuote-0.003/lib |     34300 |      29.1 |                 0.00% |               379.70% | 1.3e-08 |      21 |
 | long    | PERL5OPT=-Iarchive/String-PodQuote-0.002/lib |     34400 |      29.1 |                 0.18% |               378.86% | 1.2e-08 |      26 |
 | short   | PERL5OPT=-Iarchive/String-PodQuote-0.002/lib |    160000 |       6.1 |               376.81% |                 0.61% | 1.3e-08 |      20 |
 | short   | PERL5OPT=-Iarchive/String-PodQuote-0.003/lib |    160000 |       6.1 |               379.70% |                 0.00% | 6.7e-09 |      20 |
 +---------+----------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

             Rate  long  long  short  short 
  long    34300/s    --    0%   -79%   -79% 
  long    34400/s    0%    --   -79%   -79% 
  short  160000/s  377%  377%     --     0% 
  short  160000/s  377%  377%     0%     -- 
 
 Legends:
   long: dataset=long env=PERL5OPT=-Iarchive/String-PodQuote-0.002/lib
   short: dataset=short env=PERL5OPT=-Iarchive/String-PodQuote-0.003/lib

Benchmark module startup overhead (C<< bencher -m String::PodQuote --module-startup >>):

 #table2#
 +---------------------+----------------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | env                                          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+----------------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::PodQuote    | PERL5OPT=-Iarchive/String-PodQuote-0.003/lib |       9.5 |               2.8 |                 0.00% |                49.00% | 6.5e-05 |      20 |
 | String::PodQuote    | PERL5OPT=-Iarchive/String-PodQuote-0.002/lib |       9.3 |               2.6 |                 2.64% |                45.17% | 4.9e-05 |      20 |
 | perl -e1 (baseline) | PERL5OPT=-Iarchive/String-PodQuote-0.003/lib |       6.7 |               0   |                41.93% |                 4.98% | 4.5e-05 |      21 |
 | perl -e1 (baseline) | PERL5OPT=-Iarchive/String-PodQuote-0.002/lib |       6.4 |              -0.3 |                49.00% |                 0.00% | 2.1e-05 |      21 |
 +---------------------+----------------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  String::PodQuote  String::PodQuote  perl -e1 (baseline)  perl -e1 (baseline) 
  String::PodQuote     105.3/s                --               -2%                 -29%                 -32% 
  String::PodQuote     107.5/s                2%                --                 -27%                 -31% 
  perl -e1 (baseline)  149.3/s               41%               38%                   --                  -4% 
  perl -e1 (baseline)  156.2/s               48%               45%                   4%                   -- 
 
 Legends:
   String::PodQuote: env=PERL5OPT=-Iarchive/String-PodQuote-0.002/lib mod_overhead_time=2.6 participant=String::PodQuote
   perl -e1 (baseline): env=PERL5OPT=-Iarchive/String-PodQuote-0.002/lib mod_overhead_time=-0.3 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-String-PodQuote>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-StringPodQuote>.

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-String-PodQuote>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
