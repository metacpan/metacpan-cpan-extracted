package Bencher::Scenario::Array::Set::startup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenarios-Array-Set'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark startup of Array::Set',
    module_startup => 1,
    modules => {
    },
    participants => [
        {module=>'Array::Set'},
        {module=>'Set::Object'},
        {module=>'Set::Scalar'},
    ],
};

1;
# ABSTRACT: Benchmark startup of Array::Set

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Array::Set::startup - Benchmark startup of Array::Set

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Array::Set::startup (from Perl distribution Bencher-Scenarios-Array-Set), released on 2021-10-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Array::Set::startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::Set> 0.063

L<Set::Object> 1.41

L<Set::Scalar> 1.29

=head1 BENCHMARK PARTICIPANTS

=over

=item * Array::Set (perl_code)

L<Array::Set>



=item * Set::Object (perl_code)

L<Set::Object>



=item * Set::Scalar (perl_code)

L<Set::Scalar>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with C<< bencher -m Array::Set::startup --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>undef}
 +---------------------+--------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | modver | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+--------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Set::Object         | 0.02   |      19   |              16.3 |                 0.00% |               637.92% | 2.2e-05 |      20 |
 | Set::Object         | 0.05   |      19   |              16.3 |                 0.16% |               636.73% | 1.5e-05 |      20 |
 | Set::Object         | 0.063  |      19   |              16.3 |                 0.21% |               636.37% | 2.3e-05 |      20 |
 | Set::Scalar         | 0.02   |      16   |              13.3 |                17.69% |               527.01% | 3.8e-05 |      21 |
 | Set::Scalar         | 0.05   |      15.9 |              13.2 |                19.68% |               516.57% | 1.3e-05 |      21 |
 | Set::Scalar         | 0.063  |      16   |              13.3 |                19.95% |               515.21% |   2e-05 |      20 |
 | Array::Set          | 0.02   |      14   |              11.3 |                33.41% |               453.12% | 2.8e-05 |      20 |
 | Array::Set          | 0.063  |       7.7 |               5   |               146.51% |               199.34% | 1.7e-05 |      20 |
 | Array::Set          | 0.05   |       7.4 |               4.7 |               155.64% |               188.65% | 1.1e-05 |      20 |
 | perl -e1 (baseline) | 0.02   |       2.7 |               0   |               602.55% |                 5.03% | 6.8e-06 |      21 |
 | perl -e1 (baseline) | 0.063  |       2.6 |              -0.1 |               623.82% |                 1.95% | 8.5e-06 |      21 |
 | perl -e1 (baseline) | 0.05   |       2.6 |              -0.1 |               637.92% |                 0.00% | 1.8e-05 |      20 |
 +---------------------+--------+-----------+-------------------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  Set::Object  Set::Object  Set::Object  Set::Scalar  Set::Scalar  Set::Scalar  Array::Set  Array::Set  Array::Set  perl -e1 (baseline)  perl -e1 (baseline)  perl -e1 (baseline) 
  Set::Object           52.6/s           --           0%           0%         -15%         -15%         -16%        -26%        -59%        -61%                 -85%                 -86%                 -86% 
  Set::Object           52.6/s           0%           --           0%         -15%         -15%         -16%        -26%        -59%        -61%                 -85%                 -86%                 -86% 
  Set::Object           52.6/s           0%           0%           --         -15%         -15%         -16%        -26%        -59%        -61%                 -85%                 -86%                 -86% 
  Set::Scalar           62.5/s          18%          18%          18%           --           0%           0%        -12%        -51%        -53%                 -83%                 -83%                 -83% 
  Set::Scalar           62.5/s          18%          18%          18%           0%           --           0%        -12%        -51%        -53%                 -83%                 -83%                 -83% 
  Set::Scalar           62.9/s          19%          19%          19%           0%           0%           --        -11%        -51%        -53%                 -83%                 -83%                 -83% 
  Array::Set            71.4/s          35%          35%          35%          14%          14%          13%          --        -44%        -47%                 -80%                 -81%                 -81% 
  Array::Set           129.9/s         146%         146%         146%         107%         107%         106%         81%          --         -3%                 -64%                 -66%                 -66% 
  Array::Set           135.1/s         156%         156%         156%         116%         116%         114%         89%          4%          --                 -63%                 -64%                 -64% 
  perl -e1 (baseline)  370.4/s         603%         603%         603%         492%         492%         488%        418%        185%        174%                   --                  -3%                  -3% 
  perl -e1 (baseline)  384.6/s         630%         630%         630%         515%         515%         511%        438%        196%        184%                   3%                   --                   0% 
  perl -e1 (baseline)  384.6/s         630%         630%         630%         515%         515%         511%        438%        196%        184%                   3%                   0%                   -- 
 
 Legends:
   Array::Set: mod_overhead_time=4.7 modver=0.05 participant=Array::Set
   Set::Object: mod_overhead_time=16.3 modver=0.063 participant=Set::Object
   Set::Scalar: mod_overhead_time=13.2 modver=0.05 participant=Set::Scalar
   perl -e1 (baseline): mod_overhead_time=-0.1 modver=0.05 participant=perl -e1 (baseline)


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Array-Set>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Array-Set>.

=head1 SEE ALSO

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

This software is copyright (c) 2021, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Array-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
