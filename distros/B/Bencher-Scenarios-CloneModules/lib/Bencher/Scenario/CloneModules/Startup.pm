package Bencher::Scenario::CloneModules::Startup;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.051'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of various data cloning modules',
    module_startup => 1,
    modules => {
        'Clone::Util' => {version=>0.03},
    },
    participants => [
        {module=>'Clone'},
        {module=>'Clone::PP'},
        #{module=>'Clone::Any'}, # i no longer recommend using this
        {module=>'Clone::Util'},
        {module=>'Data::Clone'},
        {module=>'Function::Fallback::CoreOrPP'},
        {module=>'Sereal::Dclone'},
        {module=>'Storable'},
    ],
    #datasets => [
    #],
    on_failure => 'skip',
};

1;
# ABSTRACT: Benchmark startup of various data cloning modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CloneModules::Startup - Benchmark startup of various data cloning modules

=head1 VERSION

This document describes version 0.051 of Bencher::Scenario::CloneModules::Startup (from Perl distribution Bencher-Scenarios-CloneModules), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CloneModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Clone> 0.45

L<Clone::PP> 1.08

L<Clone::Util> 0.03

L<Data::Clone> 0.004

L<Function::Fallback::CoreOrPP> 0.090

L<Sereal::Dclone> 0.003

L<Storable> 3.23

=head1 BENCHMARK PARTICIPANTS

=over

=item * Clone (perl_code)

L<Clone>



=item * Clone::PP (perl_code)

L<Clone::PP>



=item * Clone::Util (perl_code)

L<Clone::Util>



=item * Data::Clone (perl_code)

L<Data::Clone>



=item * Function::Fallback::CoreOrPP (perl_code)

L<Function::Fallback::CoreOrPP>



=item * Sereal::Dclone (perl_code)

L<Sereal::Dclone>



=item * Storable (perl_code)

L<Storable>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (cloning a 10k-element array):

 % bencher -m CloneModules::Startup --include-datasets array10k

Result formatted as table:

 #table1#
 +------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                  | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Sereal::Dclone               |        10 |                 5 |                 0.00% |               148.21% |   0.0003  |      20 |
 | Storable                     |        10 |                 5 |                 0.55% |               146.86% |   0.00016 |      21 |
 | Clone                        |        10 |                 5 |                24.57% |                99.25% |   0.00023 |      21 |
 | Clone::Util                  |         8 |                 3 |                52.22% |                63.06% |   0.00015 |      20 |
 | Clone::PP                    |         8 |                 3 |                53.43% |                61.77% |   0.00014 |      20 |
 | Function::Fallback::CoreOrPP |         7 |                 2 |                66.11% |                49.42% |   0.00013 |      20 |
 | Data::Clone                  |         7 |                 2 |                70.32% |                45.73% | 9.3e-05   |      20 |
 | perl -e1 (baseline)          |         5 |                 0 |               148.21% |                 0.00% | 1.2e-05   |      20 |
 +------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate   S:D     S     C   C:U   C:P  FF:C   D:C  perl -e1 (baseline) 
  S:D                  100.0/s    --    0%    0%  -19%  -19%  -30%  -30%                 -50% 
  S                    100.0/s    0%    --    0%  -19%  -19%  -30%  -30%                 -50% 
  C                    100.0/s    0%    0%    --  -19%  -19%  -30%  -30%                 -50% 
  C:U                  125.0/s   25%   25%   25%    --    0%  -12%  -12%                 -37% 
  C:P                  125.0/s   25%   25%   25%    0%    --  -12%  -12%                 -37% 
  FF:C                 142.9/s   42%   42%   42%   14%   14%    --    0%                 -28% 
  D:C                  142.9/s   42%   42%   42%   14%   14%    0%    --                 -28% 
  perl -e1 (baseline)  200.0/s  100%  100%  100%   60%   60%   39%   39%                   -- 
 
 Legends:
   C: mod_overhead_time=5 participant=Clone
   C:P: mod_overhead_time=3 participant=Clone::PP
   C:U: mod_overhead_time=3 participant=Clone::Util
   D:C: mod_overhead_time=2 participant=Data::Clone
   FF:C: mod_overhead_time=2 participant=Function::Fallback::CoreOrPP
   S: mod_overhead_time=5 participant=Storable
   S:D: mod_overhead_time=5 participant=Sereal::Dclone
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command (cloning a 10k-pair hash):

 % bencher -m CloneModules::Startup --include-datasets hash10k

Result formatted as table:

 #table2#
 +------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                  | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Storable                     |        12 |                 6 |                 0.00% |               104.42% |   9e-05   |      20 |
 | Sereal::Dclone               |        11 |                 5 |                10.59% |                84.85% | 3.3e-05   |      21 |
 | Clone                        |        10 |                 4 |                19.86% |                70.56% |   0.00038 |      20 |
 | Clone::PP                    |         9 |                 3 |                42.88% |                43.08% |   0.00016 |      20 |
 | Function::Fallback::CoreOrPP |         8 |                 2 |                45.88% |                40.13% |   0.00015 |      20 |
 | Clone::Util                  |         8 |                 2 |                49.01% |                37.19% | 8.3e-05   |      20 |
 | Data::Clone                  |         7 |                 1 |                66.39% |                22.86% |   0.0001  |      20 |
 | perl -e1 (baseline)          |         6 |                 0 |               104.42% |                 0.00% | 6.7e-05   |      20 |
 +------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate     S  S:D     C   C:P  FF:C   C:U   D:C  perl -e1 (baseline) 
  S                     83.3/s    --  -8%  -16%  -25%  -33%  -33%  -41%                 -50% 
  S:D                   90.9/s    9%   --   -9%  -18%  -27%  -27%  -36%                 -45% 
  C                    100.0/s   19%  10%    --   -9%  -19%  -19%  -30%                 -40% 
  C:P                  111.1/s   33%  22%   11%    --  -11%  -11%  -22%                 -33% 
  FF:C                 125.0/s   50%  37%   25%   12%    --    0%  -12%                 -25% 
  C:U                  125.0/s   50%  37%   25%   12%    0%    --  -12%                 -25% 
  D:C                  142.9/s   71%  57%   42%   28%   14%   14%    --                 -14% 
  perl -e1 (baseline)  166.7/s  100%  83%   66%   50%   33%   33%   16%                   -- 
 
 Legends:
   C: mod_overhead_time=4 participant=Clone
   C:P: mod_overhead_time=3 participant=Clone::PP
   C:U: mod_overhead_time=2 participant=Clone::Util
   D:C: mod_overhead_time=1 participant=Data::Clone
   FF:C: mod_overhead_time=2 participant=Function::Fallback::CoreOrPP
   S: mod_overhead_time=6 participant=Storable
   S:D: mod_overhead_time=5 participant=Sereal::Dclone
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CloneModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CloneModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CloneModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
