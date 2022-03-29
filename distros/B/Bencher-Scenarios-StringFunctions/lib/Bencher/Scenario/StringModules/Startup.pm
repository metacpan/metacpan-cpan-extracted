package Bencher::Scenario::StringModules::Startup;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'Bencher-Scenarios-StringFunctions'; # DIST
our $VERSION = '0.006'; # VERSION

our $scenario = {
    summary => 'Benchmark startup of string modules',
    module_startup => 1,
    participants => [
        {module => 'String::CommonPrefix'},
        {module => 'String::CommonSuffix'},
        {module => 'String::Trim::More'},
        {module => 'String::Util'},
        {module => 'Text::Minify::XS'},
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

This document describes version 0.006 of Bencher::Scenario::StringModules::Startup (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2022-03-27.

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

L<Text::Minify::XS> v0.6.1

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



=item * Text::Minify::XS (perl_code)

L<Text::Minify::XS>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m StringModules::Startup >>):

 #table1#
 {dataset=>undef}
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::Util         |     14.3  |              8.1  |                 0.00% |               131.58% |   1e-05 |      20 |
 | Text::Minify::XS     |      9.35 |              3.15 |                52.82% |                51.54% | 4.5e-06 |      20 |
 | String::Trim::More   |      9.08 |              2.88 |                57.37% |                47.16% | 8.7e-06 |      20 |
 | String::CommonSuffix |      8.95 |              2.75 |                59.67% |                45.04% | 8.1e-06 |      20 |
 | String::CommonPrefix |      8.9  |              2.7  |                59.85% |                44.88% | 9.8e-06 |      20 |
 | perl -e1 (baseline)  |      6.2  |              0    |               131.58% |                 0.00% | 6.7e-06 |      20 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                           Rate  String::Util  Text::Minify::XS  String::Trim::More  String::CommonSuffix  String::CommonPrefix  perl -e1 (baseline) 
  String::Util           69.9/s            --              -34%                -36%                  -37%                  -37%                 -56% 
  Text::Minify::XS      107.0/s           52%                --                 -2%                   -4%                   -4%                 -33% 
  String::Trim::More    110.1/s           57%                2%                  --                   -1%                   -1%                 -31% 
  String::CommonSuffix  111.7/s           59%                4%                  1%                    --                    0%                 -30% 
  String::CommonPrefix  112.4/s           60%                5%                  2%                    0%                    --                 -30% 
  perl -e1 (baseline)   161.3/s          130%               50%                 46%                   44%                   43%                   -- 
 
 Legends:
   String::CommonPrefix: mod_overhead_time=2.7 participant=String::CommonPrefix
   String::CommonSuffix: mod_overhead_time=2.75 participant=String::CommonSuffix
   String::Trim::More: mod_overhead_time=2.88 participant=String::Trim::More
   String::Util: mod_overhead_time=8.1 participant=String::Util
   Text::Minify::XS: mod_overhead_time=3.15 participant=Text::Minify::XS
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

=for html <img src="data:image/png;base64,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" />


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

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

This software is copyright (c) 2022, 2021, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
