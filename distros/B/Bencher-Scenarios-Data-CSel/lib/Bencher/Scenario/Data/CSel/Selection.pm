package Bencher::Scenario::Data::CSel::Selection;

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::Data::CSel;
use PERLANCAR::Tree::Examples qw(gen_sample_data);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenarios-Data-CSel'; # DIST
our $VERSION = '0.041'; # VERSION

my @exprs = (
    'Sub4',
    'Sub4:first-child',
);

my @datasets = do {
    my @res = @Bencher::ScenarioUtil::Data::CSel::datasets;
    for (@res) {
        $_->{args}{'expr@'} = \@exprs;
    }
    @res;
};

our $scenario = {
    summary => 'Benchmark selector',
    description => <<'_',

Sample documents from `PERLANCAR::HTML::Tree::Examples` are used.

_
    before_gen_items => sub {
        # prepare trees
        %main::trees = ();
        for (@Bencher::ScenarioUtil::Data::CSel::datasets) {
            $_->{name} =~ /(.+)-(.+)/ or die;
            $main::trees{$_->{name}} = gen_sample_data(size=>$1, backend=>$2);
        }
    },
    modules => {
        'Data::CSel' => {version=>0.04},
    },
    participants => [
        {
            module => 'Data::CSel',
            code_template => 'my @res = Data::CSel::csel({class_prefixes=>["Tree::Example::HashNode", "Tree::Example::ArrayNode"]}, <expr>, $main::trees{<tree>}); scalar @res',
        },
    ],
    datasets => \@datasets,
    extra_modules => \@Bencher::ScenarioUtil::Data::CSel::extra_modules,
};

1;
# ABSTRACT: Benchmark selector

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::CSel::Selection - Benchmark selector

=head1 VERSION

This document describes version 0.041 of Bencher::Scenario::Data::CSel::Selection (from Perl distribution Bencher-Scenarios-Data-CSel), released on 2023-01-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::CSel::Selection

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::CSel::Selection

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Sample documents from C<PERLANCAR::HTML::Tree::Examples> are used.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::CSel> 0.128

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::CSel (perl_code)

Code template:

 my @res = Data::CSel::csel({class_prefixes=>["Tree::Example::HashNode", "Tree::Example::ArrayNode"]}, <expr>, $main::trees{<tree>}); scalar @res



=back

=head1 BENCHMARK DATASETS

=over

=item * small1-hash

16 elements, 4 levels (hash-based nodes).

=item * small1-array

16 elements, 4 levels (array-based nodes).

=item * medium1-hash

20k elements, 7 levels (hash-based nodes).

=item * medium1-array

20k elements, 7 levels (array-based nodes).

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::CSel::Selection >>):

 #table1#
 +---------------+------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | dataset       | arg_expr         | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------+------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | medium1-array | Sub4:first-child |        16 |   62      |                 0.00% |            117641.82% |   0.0001  |      20 |
 | medium1-hash  | Sub4:first-child |        17 |   60      |                 2.06% |            115263.45% |   8e-05   |      20 |
 | medium1-array | Sub4             |        21 |   49      |                26.60% |             92904.89% |   0.00018 |      20 |
 | medium1-hash  | Sub4             |        21 |   48      |                27.79% |             92039.81% | 9.5e-05   |      20 |
 | small1-hash   | Sub4:first-child |     13500 |    0.0743 |             82729.42% |                42.15% | 2.6e-08   |      21 |
 | small1-array  | Sub4:first-child |     15000 |    0.065  |             93982.88% |                25.15% | 9.9e-08   |      23 |
 | small1-hash   | Sub4             |     16000 |    0.062  |             98974.93% |                18.84% | 1.1e-07   |      31 |
 | small1-array  | Sub4             |     19000 |    0.052  |            117641.82% |                 0.00% | 9.2e-08   |      27 |
 +---------------+------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                     Rate  medium1-array Sub4:first-child  medium1-hash Sub4:first-child  medium1-array Sub4  medium1-hash Sub4  small1-hash Sub4:first-child  small1-array Sub4:first-child  small1-hash Sub4  small1-array Sub4 
  medium1-array Sub4:first-child     16/s                              --                            -3%                -20%               -22%                          -99%                           -99%              -99%               -99% 
  medium1-hash Sub4:first-child      17/s                              3%                             --                -18%               -19%                          -99%                           -99%              -99%               -99% 
  medium1-array Sub4                 21/s                             26%                            22%                  --                -2%                          -99%                           -99%              -99%               -99% 
  medium1-hash Sub4                  21/s                             29%                            25%                  2%                 --                          -99%                           -99%              -99%               -99% 
  small1-hash Sub4:first-child    13500/s                          83345%                         80653%              65848%             64502%                            --                           -12%              -16%               -30% 
  small1-array Sub4:first-child   15000/s                          95284%                         92207%              75284%             73746%                           14%                             --               -4%               -20% 
  small1-hash Sub4                16000/s                          99900%                         96674%              78932%             77319%                           19%                             4%                --               -16% 
  small1-array Sub4               19000/s                         119130%                        115284%              94130%             92207%                           42%                            25%               19%                 -- 
 
 Legends:
   medium1-array Sub4: arg_expr=Sub4 dataset=medium1-array
   medium1-array Sub4:first-child: arg_expr=Sub4:first-child dataset=medium1-array
   medium1-hash Sub4: arg_expr=Sub4 dataset=medium1-hash
   medium1-hash Sub4:first-child: arg_expr=Sub4:first-child dataset=medium1-hash
   small1-array Sub4: arg_expr=Sub4 dataset=small1-array
   small1-array Sub4:first-child: arg_expr=Sub4:first-child dataset=small1-array
   small1-hash Sub4: arg_expr=Sub4 dataset=small1-hash
   small1-hash Sub4:first-child: arg_expr=Sub4:first-child dataset=small1-hash

Benchmark module startup overhead (C<< bencher -m Data::CSel::Selection --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::CSel          |      16   |               8.4 |                 0.00% |               105.24% | 8.5e-05 |      20 |
 | perl -e1 (baseline) |       7.6 |               0   |               105.24% |                 0.00% | 3.3e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   D:C  perl -e1 (baseline) 
  D:C                   62.5/s    --                 -52% 
  perl -e1 (baseline)  131.6/s  110%                   -- 
 
 Legends:
   D:C: mod_overhead_time=8.4 participant=Data::CSel
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-CSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-CSel>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-CSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
