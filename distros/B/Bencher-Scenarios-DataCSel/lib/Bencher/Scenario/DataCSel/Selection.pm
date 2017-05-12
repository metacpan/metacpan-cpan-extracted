package Bencher::Scenario::DataCSel::Selection;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::DataCSel;
use PERLANCAR::Tree::Examples qw(gen_sample_data);

my @exprs = (
    'Sub4',
    'Sub4:first-child',
);

my @datasets = do {
    my @res = @Bencher::ScenarioUtil::DataCSel::datasets;
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
        for (@Bencher::ScenarioUtil::DataCSel::datasets) {
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
    extra_modules => \@Bencher::ScenarioUtil::DataCSel::extra_modules,
};

1;
# ABSTRACT: Benchmark selector

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataCSel::Selection - Benchmark selector

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::DataCSel::Selection (from Perl distribution Bencher-Scenarios-DataCSel), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCSel::Selection

To run module startup overhead benchmark:

 % bencher --module-startup -m DataCSel::Selection

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Sample documents from C<PERLANCAR::HTML::Tree::Examples> are used.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::CSel> 0.11

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::CSel (perl_code)

Code template:

 my @res = Data::CSel::csel({class_prefixes=>["Tree::Example::HashNode", "Tree::Example::ArrayNode"]}, <expr>, $main::trees{<tree>}); scalar @res



=back

=head1 BENCHMARK DATASETS

=over

=item * small1-hash

16 elements, 4 levels (hash-based nodes)

=item * small1-array

16 elements, 4 levels (array-based nodes)

=item * medium1-hash

20k elements, 7 levels (hash-based nodes)

=item * medium1-array

20k elements, 7 levels (array-based nodes)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataCSel::Selection >>):

 #table1#
 +---------------+------------------+-----------+-----------+------------+-----------+---------+
 | dataset       | arg_expr         | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------------+------------------+-----------+-----------+------------+-----------+---------+
 | medium1-array | Sub4:first-child |        15 |    69     |        1   |   0.00016 |      20 |
 | medium1-hash  | Sub4:first-child |        15 |    68     |        1   |   0.0002  |      20 |
 | medium1-hash  | Sub4             |        18 |    55     |        1.3 |   0.00021 |      20 |
 | medium1-array | Sub4             |        19 |    54     |        1.3 |   0.00019 |      20 |
 | small1-hash   | Sub4:first-child |     12000 |     0.082 |      830   |   2e-07   |      29 |
 | small1-array  | Sub4:first-child |     13000 |     0.08  |      860   | 9.4e-08   |      26 |
 | small1-hash   | Sub4             |     15000 |     0.066 |     1000   | 1.9e-07   |      20 |
 | small1-array  | Sub4             |     16000 |     0.064 |     1100   | 1.2e-07   |      26 |
 +---------------+------------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m DataCSel::Selection --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Data::CSel          | 0.82                         | 4.1                | 16             |      14   |                    7.4 |        1   | 5.3e-05 |      20 |
 | perl -e1 (baseline) | 1.6                          | 5                  | 19             |       6.6 |                    0   |        2.1 | 2.2e-05 |      21 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataCSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataCSel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataCSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
