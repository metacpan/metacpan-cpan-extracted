package Bencher::Scenario::Text::Table::Sprintf::Startup;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-11'; # DATE
our $DIST = 'Bencher-Scenarios-Text-Table-Sprintf'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    module_startup => 1,
    modules => {
    },
    participants => [
        {module => 'Text::Table::Sprintf'},
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Text::Table::Sprintf::Startup

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Text::Table::Sprintf::Startup (from Perl distribution Bencher-Scenarios-Text-Table-Sprintf), released on 2023-11-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Text::Table::Sprintf::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Sprintf> 0.008

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Table::Sprintf (perl_code)

L<Text::Table::Sprintf>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command:

 % bencher -m Text::Table::Sprintf::Startup --include-path archive/Text-Table-Sprintf-0.006/lib --include-path archive/Text-Table-Sprintf-0.007/lib --multimodver Text::Table::Sprintf

Result formatted as table:

 #table1#
 +----------------------+--------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | modver | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+--------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Sprintf | 0.008  |       2.4 |               0.4 |                 0.00% |                23.55% | 9.4e-06 |      20 |
 | Text::Table::Sprintf | 0.007  |       2.4 |               0.4 |                 0.02% |                23.53% | 8.6e-06 |      20 |
 | Text::Table::Sprintf | 0.006  |       2.3 |               0.3 |                 4.44% |                18.30% | 6.5e-06 |      20 |
 | perl -e1 (baseline)  | 0.008  |       2   |               0   |                17.83% |                 4.86% | 2.2e-05 |      21 |
 | perl -e1 (baseline)  | 0.006  |       2   |               0   |                20.42% |                 2.60% | 1.2e-05 |      20 |
 | perl -e1 (baseline)  | 0.007  |       1.9 |              -0.1 |                23.55% |                 0.00% | 6.2e-06 |      20 |
 +----------------------+--------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                           Rate  Text::Table::Sprintf  Text::Table::Sprintf  Text::Table::Sprintf  perl -e1 (baseline)  perl -e1 (baseline)  perl -e1 (baseline) 
  Text::Table::Sprintf  416.7/s                    --                    0%                   -4%                 -16%                 -16%                 -20% 
  Text::Table::Sprintf  416.7/s                    0%                    --                   -4%                 -16%                 -16%                 -20% 
  Text::Table::Sprintf  434.8/s                    4%                    4%                    --                 -13%                 -13%                 -17% 
  perl -e1 (baseline)   500.0/s                   19%                   19%                   14%                   --                   0%                  -5% 
  perl -e1 (baseline)   500.0/s                   19%                   19%                   14%                   0%                   --                  -5% 
  perl -e1 (baseline)   526.3/s                   26%                   26%                   21%                   5%                   5%                   -- 
 
 Legends:
   Text::Table::Sprintf: mod_overhead_time=0.3 modver=0.006 participant=Text::Table::Sprintf
   perl -e1 (baseline): mod_overhead_time=-0.1 modver=0.007 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Text-Table-Sprintf>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Text-Table-Sprintf>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Text-Table-Sprintf>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
