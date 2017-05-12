package Bencher::Scenario::MojoDOM::Parsing;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::MojoDOM;
use PERLANCAR::HTML::Tree::Examples qw(gen_sample_data);

our $scenario = {
    summary => 'Benchmark parsing of HTML',
    description => <<'_',

Sample documents from `PERLANCAR::HTML::Tree::Examples` are used.

_
    before_gen_items => sub {
        # prepare html
        %main::htmls = map {
            ($_->{name} => gen_sample_data(size => $_->{name}))
        } @Bencher::ScenarioUtil::MojoDOM::datasets;
    },
    participants => [
        {
            fcall_template => 'Mojo::DOM->new($main::htmls{<size>})',
        },
    ],
    datasets => \@Bencher::ScenarioUtil::MojoDOM::datasets,
    include_result_size => 1,
    extra_modules => \@Bencher::ScenarioUtil::MojoDOM::extra_modules,
};

1;
# ABSTRACT: Benchmark parsing of HTML

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::MojoDOM::Parsing - Benchmark parsing of HTML

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::MojoDOM::Parsing (from Perl distribution Bencher-Scenarios-MojoDOM), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m MojoDOM::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m MojoDOM::Parsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Sample documents from C<PERLANCAR::HTML::Tree::Examples> are used.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Mojo::DOM>

=head1 BENCHMARK PARTICIPANTS

=over

=item * Mojo::DOM::new (perl_code)

Function call template:

 Mojo::DOM->new($main::htmls{<size>})



=back

=head1 BENCHMARK DATASETS

=over

=item * small1

16 elements, 4 levels

=item * medium1

20k elements, 7 levels

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m MojoDOM::Parsing >>):

 #table1#
 +---------+----------------+-----------+-----------+------------+-----------+---------+
 | dataset | arg_expr       | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------+----------------+-----------+-----------+------------+-----------+---------+
 | medium1 | h4:first-child |       1.9 |   530     |        1   |   0.005   |      23 |
 | medium1 | h4             |       2   |   500     |        1.1 |   0.00074 |      20 |
 | small1  | h4             |    2500   |     0.4   |     1300   | 4.3e-07   |      20 |
 | small1  | h4:first-child |    2520   |     0.397 |     1350   | 2.6e-07   |      21 |
 +---------+----------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m MojoDOM::Parsing --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Mojo::DOM           | 0.82                         | 4                  | 16             |      57   |                   49.7 |        1   |   0.00013 |      20 |
 | perl -e1 (baseline) | 6.7                          | 10                 | 44             |       7.3 |                    0   |        7.8 | 1.9e-05   |      22 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-MojoDOM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-MojoDOM>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-MojoDOM>

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
