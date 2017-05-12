package Bencher::Scenario::MojoDOM::Selection;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::MojoDOM;
use Mojo::DOM;
use PERLANCAR::HTML::Tree::Examples qw(gen_sample_data);

my @exprs = (
    'h4',
    'h4:first-child',
);

my @datasets = do {
    my @res = @Bencher::ScenarioUtil::MojoDOM::datasets;
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
        # prepare the DOMs
        %main::doms = map {
            ($_->{name} => Mojo::DOM->new(
                gen_sample_data(size => $_->{name})))
        } @Bencher::ScenarioUtil::MojoDOM::datasets;
    },
    participants => [
        {
            name => 'find',
            code_template => '$main::doms{<size>}->find(<expr>)->size',
        },
    ],
    datasets => \@datasets,
    extra_modules => \@Bencher::ScenarioUtil::MojoDOM::extra_modules,
};

1;
# ABSTRACT: Benchmark selector

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::MojoDOM::Selection - Benchmark selector

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::MojoDOM::Selection (from Perl distribution Bencher-Scenarios-MojoDOM), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m MojoDOM::Selection

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Sample documents from C<PERLANCAR::HTML::Tree::Examples> are used.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * find (perl_code)

Code template:

 $main::doms{<size>}->find(<expr>)->size



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

Benchmark with default options (C<< bencher -m MojoDOM::Selection >>):

 #table1#
 +---------+----------------+-----------+-----------+------------+-----------+---------+
 | dataset | arg_expr       | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------+----------------+-----------+-----------+------------+-----------+---------+
 | medium1 | h4:first-child |       8.5 |   120     |        1   |   0.00053 |      20 |
 | medium1 | h4             |      11   |    94     |        1.2 |   0.00058 |      20 |
 | small1  | h4:first-child |   12000   |     0.081 |     1500   | 1.1e-07   |      20 |
 | small1  | h4             |   14000   |     0.07  |     1700   | 3.5e-07   |      20 |
 +---------+----------------+-----------+-----------+------------+-----------+---------+


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
