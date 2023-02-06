package Bencher::Scenario::Regexp::Assemble;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-Regexp-Assemble'; # DIST
our $VERSION = '0.040'; # VERSION

$main::chars = ["a".."z"];

my $code_template_assemble_with_ra = 'my $ra = Regexp::Assemble->new; for (1.. <num> ) { $ra->add(join("", map {$main::chars->[rand @$main::chars]} 1..10)) } $ra->re';
my $code_template_assemble_raw     = 'my @strs; for (1.. <num> ) { push @strs, join("", map {$main::chars->[rand @$main::chars]} 1..10) } my $re = "\\\\A(?:".join("|", map {quotemeta} sort {length($b) <=> length($a)} @strs).")\\\\z"; $re = qr/$re/';

our $scenario = {
    summary => 'Benchmark Regexp::Assemble',
    participants => [
        {
            name => 'assemble-with-ra',
            module=>'Regexp::Assemble',
            code_template => $code_template_assemble_with_ra,
            tags => ['assembling'],
        },
        {
            name => 'assemble-raw',
            code_template => $code_template_assemble_raw,
            tags => ['assembling'],
        },
        {
            name => 'match-with-ra',
            module=>'Regexp::Assemble',
            code_template => 'state $re = do { ' . $code_template_assemble_with_ra . ' }; state $str = join("", map {$main::chars->[rand @$main::chars]} 1..10); $str =~ $re',
            tags => ['matching'],
        },
        {
            name => 'match-raw',
            code_template => 'state $re = do { ' . $code_template_assemble_raw     . ' }; state $str = join("", map {$main::chars->[rand @$main::chars]} 1..10); $str =~ $re',
            tags => ['matching'],
        },
    ],
    datasets => [
        {name=>'10str'   , args=>{num=>10   }},
        {name=>'100str'  , args=>{num=>100  }},
        {name=>'1000str' , args=>{num=>1000 }},
        {name=>'10000str', args=>{num=>10000}},
    ],
};

1;
# ABSTRACT: Benchmark Regexp::Assemble

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Regexp::Assemble - Benchmark Regexp::Assemble

=head1 VERSION

This document describes version 0.040 of Bencher::Scenario::Regexp::Assemble (from Perl distribution Bencher-Scenario-Regexp-Assemble), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Regexp::Assemble

To run module startup overhead benchmark:

 % bencher --module-startup -m Regexp::Assemble

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::Assemble> 0.38

=head1 BENCHMARK PARTICIPANTS

=over

=item * assemble-with-ra (perl_code) [assembling]

Code template:

 my $ra = Regexp::Assemble->new; for (1.. <num> ) { $ra->add(join("", map {$main::chars->[rand @$main::chars]} 1..10)) } $ra->re



=item * assemble-raw (perl_code) [assembling]

Code template:

 my @strs; for (1.. <num> ) { push @strs, join("", map {$main::chars->[rand @$main::chars]} 1..10) } my $re = "\\A(?:".join("|", map {quotemeta} sort {length($b) <=> length($a)} @strs).")\\z"; $re = qr/$re/



=item * match-with-ra (perl_code) [matching]

Code template:

 state $re = do { my $ra = Regexp::Assemble->new; for (1.. <num> ) { $ra->add(join("", map {$main::chars->[rand @$main::chars]} 1..10)) } $ra->re }; state $str = join("", map {$main::chars->[rand @$main::chars]} 1..10); $str =~ $re



=item * match-raw (perl_code) [matching]

Code template:

 state $re = do { my @strs; for (1.. <num> ) { push @strs, join("", map {$main::chars->[rand @$main::chars]} 1..10) } my $re = "\\A(?:".join("|", map {quotemeta} sort {length($b) <=> length($a)} @strs).")\\z"; $re = qr/$re/ }; state $str = join("", map {$main::chars->[rand @$main::chars]} 1..10); $str =~ $re



=back

=head1 BENCHMARK DATASETS

=over

=item * 10str

=item * 100str

=item * 1000str

=item * 10000str

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Regexp::Assemble >>):

 #table1#
 +------------------+----------+------------+-----------+---------------+-----------------------+-----------------------+-----------+---------+
 | participant      | dataset  | p_tags     | rate (/s) |   time (ms)   | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------+----------+------------+-----------+---------------+-----------------------+-----------------------+-----------+---------+
 | assemble-with-ra | 10000str | assembling |       2.2 | 460           |                 0.00% |         199970460.38% |   0.00057 |      20 |
 | assemble-raw     | 10000str | assembling |      18.6 |  53.6         |               759.28% |          23271720.95% | 3.4e-05   |      20 |
 | assemble-with-ra | 1000str  | assembling |      24   |  42           |               994.74% |          18266398.38% |   0.0001  |      21 |
 | assemble-raw     | 1000str  | assembling |     170   |   5.9         |              7679.61% |           2570345.74% | 2.1e-05   |      20 |
 | assemble-with-ra | 100str   | assembling |     270   |   3.7         |             12192.79% |           1626630.45% | 2.6e-05   |      20 |
 | assemble-raw     | 100str   | assembling |    2300   |   0.43        |            106017.10% |            188343.29% | 6.4e-07   |      20 |
 | assemble-with-ra | 10str    | assembling |    2000   |   0.4         |            106630.48% |            187260.31% |   1e-05   |      21 |
 | assemble-raw     | 10str    | assembling |   20000   |   0.05        |            927696.08% |             21453.29% | 6.7e-08   |      20 |
 | match-with-ra    | 10000str | matching   |  440000   |   0.0023      |          20254999.84% |               887.26% | 3.3e-09   |      20 |
 | match-with-ra    | 1000str  | matching   |  450000   |   0.0022      |          20612689.65% |               870.13% | 3.3e-09   |      20 |
 | match-with-ra    | 100str   | matching   |  700000   |   0.0014      |          32256025.39% |               519.95% | 4.2e-09   |      20 |
 | match-with-ra    | 10str    | matching   | 3285000   |   0.0003044   |         151390963.99% |                32.09% | 5.7e-12   |      20 |
 | match-raw        | 1000str  | matching   | 3820000   |   0.000262    |         175909620.80% |                13.68% |   1e-10   |      20 |
 | match-raw        | 10000str | matching   | 3910880   |   0.000255697 |         180245807.57% |                10.94% |   0       |      20 |
 | match-raw        | 100str   | matching   | 3963950   |   0.000252274 |         182691653.42% |                 9.46% |   0       |      20 |
 | match-raw        | 10str    | matching   | 4340000   |   0.00023     |         199970460.38% |                 0.00% |   1e-10   |      20 |
 +------------------+----------+------------+-----------+---------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                              Rate  a assembling 10000str  a assembling 10000str  a assembling 1000str  a assembling 1000str  a assembling 100str  a assembling 100str  a assembling 10str  a assembling 10str  m matching 10000str  m matching 1000str  m matching 100str  m matching 10str  m matching 1000str  m matching 10000str  m matching 100str  m matching 10str 
  a assembling 10000str      2.2/s                     --                   -88%                  -90%                  -98%                 -99%                 -99%                -99%                -99%                 -99%                -99%               -99%              -99%                -99%                 -99%               -99%              -99% 
  a assembling 10000str     18.6/s                   758%                     --                  -21%                  -88%                 -93%                 -99%                -99%                -99%                 -99%                -99%               -99%              -99%                -99%                 -99%               -99%              -99% 
  a assembling 1000str        24/s                   995%                    27%                    --                  -85%                 -91%                 -98%                -99%                -99%                 -99%                -99%               -99%              -99%                -99%                 -99%               -99%              -99% 
  a assembling 1000str       170/s                  7696%                   808%                  611%                    --                 -37%                 -92%                -93%                -99%                 -99%                -99%               -99%              -99%                -99%                 -99%               -99%              -99% 
  a assembling 100str        270/s                 12332%                  1348%                 1035%                   59%                   --                 -88%                -89%                -98%                 -99%                -99%               -99%              -99%                -99%                 -99%               -99%              -99% 
  a assembling 100str       2300/s                106876%                 12365%                 9667%                 1272%                 760%                   --                 -6%                -88%                 -99%                -99%               -99%              -99%                -99%                 -99%               -99%              -99% 
  a assembling 10str        2000/s                114900%                 13300%                10400%                 1375%                 825%                   7%                  --                -87%                 -99%                -99%               -99%              -99%                -99%                 -99%               -99%              -99% 
  a assembling 10str       20000/s                919900%                107100%                83900%                11700%                7300%                 760%                700%                  --                 -95%                -95%               -97%              -99%                -99%                 -99%               -99%              -99% 
  m matching 10000str     440000/s              19999900%               2330334%              1825986%               256421%              160769%               18595%              17291%               2073%                   --                 -4%               -39%              -86%                -88%                 -88%               -89%              -90% 
  m matching 1000str      450000/s              20908990%               2436263%              1908990%               268081%              168081%               19445%              18081%               2172%                   4%                  --               -36%              -86%                -88%                 -88%               -88%              -89% 
  m matching 100str       700000/s              32857042%               3828471%              2999900%               421328%              264185%               30614%              28471%               3471%                  64%                 57%                 --              -78%                -81%                 -81%               -81%              -83% 
  m matching 10str       3285000/s             151116851%              17608309%             13797534%              1938139%             1215405%              141161%             131306%              16325%                 655%                622%               359%                --                -13%                 -15%               -17%              -24% 
  m matching 1000str     3820000/s             175572419%              20457915%             16030434%              2251808%             1412113%              164022%             152571%              18983%                 777%                739%               434%               16%                  --                  -2%                -3%              -12% 
  m matching 10000str    3910880/s             179900329%              20962210%             16425591%              2307318%             1446925%              168067%             156335%              19454%                 799%                760%               447%               19%                  2%                   --                -1%              -10% 
  m matching 100str      3963950/s             182341322%              21246639%             16648464%              2338626%             1466559%              170349%             158457%              19719%                 811%                772%               454%               20%                  3%                   1%                 --               -8% 
  m matching 10str       4340000/s             199999900%              23304247%             18260769%              2565117%             1608595%              186856%             173813%              21639%                 900%                856%               508%               32%                 13%                  11%                 9%                -- 
 
 Legends:
   a assembling 10000str: dataset=10000str p_tags=assembling participant=assemble-raw
   a assembling 1000str: dataset=1000str p_tags=assembling participant=assemble-raw
   a assembling 100str: dataset=100str p_tags=assembling participant=assemble-raw
   a assembling 10str: dataset=10str p_tags=assembling participant=assemble-raw
   m matching 10000str: dataset=10000str p_tags=matching participant=match-raw
   m matching 1000str: dataset=1000str p_tags=matching participant=match-raw
   m matching 100str: dataset=100str p_tags=matching participant=match-raw
   m matching 10str: dataset=10str p_tags=matching participant=match-raw

Benchmark module startup overhead (C<< bencher -m Regexp::Assemble --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Regexp::Assemble    |      27   |              19.4 |                 0.00% |               259.05% |   6e-05 |      20 |
 | perl -e1 (baseline) |       7.6 |               0   |               259.05% |                 0.00% | 2.9e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   R:A  perl -e1 (baseline) 
  R:A                   37.0/s    --                 -71% 
  perl -e1 (baseline)  131.6/s  255%                   -- 
 
 Legends:
   R:A: mod_overhead_time=19.4 participant=Regexp::Assemble
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Regexp-Assemble>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RegexpAssemble>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Regexp-Assemble>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
