package Bencher::Scenario::StringModules::Startup;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of string modules',
    module_startup => 1,
    participants => [
        {module => 'String::CommonPrefix'},
        {module => 'String::CommonSuffix'},
        {module => 'String::Trim::More'},
        {module => 'String::Util'},
    ],
};

1;
# ABSTRACT: Benchmark startup of string modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringModules::Startup - Benchmark startup of string modules

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::StringModules::Startup (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::CommonPrefix> 0.01

L<String::CommonSuffix> 0.01

L<String::Trim::More> 0.03

L<String::Util> 1.32

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::CommonPrefix (perl_code)

L<String::CommonPrefix>



=item * String::CommonSuffix (perl_code)

L<String::CommonSuffix>



=item * String::Trim::More (perl_code)

L<String::Trim::More>



=item * String::Util (perl_code)

L<String::Util>



=back

=head1 BENCHMARK SAMPLE RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m StringModules::Startup

Result formatted as table:

 #table1#
 {dataset=>undef}
 +----------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | String::Util         |      10   |               5.1 |                 0.00% |               156.50% |   0.00027 |      20 |
 | String::Trim::More   |       8   |               3.1 |                54.60% |                65.91% |   0.00014 |      20 |
 | String::CommonSuffix |       8.1 |               3.2 |                56.10% |                64.33% | 5.4e-05   |      20 |
 | String::CommonPrefix |       8   |               3.1 |                65.02% |                55.44% |   0.00014 |      21 |
 | perl -e1 (baseline)  |       4.9 |               0   |               156.50% |                 0.00% | 3.9e-05   |      20 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                         Rate  String::Util  String::CommonSuffix  String::Trim::More  String::CommonPrefix  perl -e1 (baseline) 
  String::Util          0.1/s            --                  -19%                -19%                  -19%                 -51% 
  String::CommonSuffix  0.1/s           23%                    --                 -1%                   -1%                 -39% 
  String::Trim::More    0.1/s           25%                    1%                  --                    0%                 -38% 
  String::CommonPrefix  0.1/s           25%                    1%                  0%                    --                 -38% 
  perl -e1 (baseline)   0.2/s          104%                   65%                 63%                   63%                   -- 
 
 Legends:
   String::CommonPrefix: mod_overhead_time=3.1 participant=String::CommonPrefix
   String::CommonSuffix: mod_overhead_time=3.2 participant=String::CommonSuffix
   String::Trim::More: mod_overhead_time=3.1 participant=String::Trim::More
   String::Util: mod_overhead_time=5.1 participant=String::Util
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
