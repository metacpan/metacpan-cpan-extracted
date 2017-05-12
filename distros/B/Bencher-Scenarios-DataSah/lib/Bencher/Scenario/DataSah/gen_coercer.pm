package Bencher::Scenario::DataSah::gen_coercer;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.07'; # VERSION

require Data::Sah::Coerce;

my $return_types = ['bool', 'str', 'full'];

our $scenario = {
    summary => 'Benchmark coercion',
    participants => [
        {
            name => 'gen_coercer',
            code_template => 'Data::Sah::Coerce::gen_coercer(type => <type>, coerce_to => <coerce_to>)',
        },
    ],
    datasets => [
        {
            name => 'date (coerce to float(epoch))',
            args => {
                type => 'date',
                coerce_to => 'float(epoch)',
            },
        },
        {
            name => 'date (coerce to DateTime)',
            args => {
                type => 'date',
                coerce_to => 'DateTime',
            },
        },
        {
            name => 'date (coerce to Time::Moment)',
            args => {
                type => 'date',
                coerce_to => 'Time::Moment',
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark coercion

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSah::gen_coercer - Benchmark coercion

=head1 VERSION

This document describes version 0.07 of Bencher::Scenario::DataSah::gen_coercer (from Perl distribution Bencher-Scenarios-DataSah), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSah::gen_coercer

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_coercer (perl_code)

Code template:

 Data::Sah::Coerce::gen_coercer(type => <type>, coerce_to => <coerce_to>)



=back

=head1 BENCHMARK DATASETS

=over

=item * date (coerce to float(epoch))

=item * date (coerce to DateTime)

=item * date (coerce to Time::Moment)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSah::gen_coercer >>):

 #table1#
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | dataset                       | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | date (coerce to DateTime)     |      3600 |       280 |        1   | 1.3e-06 |      20 |
 | date (coerce to Time::Moment) |      4000 |       250 |        1.1 | 6.9e-07 |      20 |
 | date (coerce to float(epoch)) |      4700 |       210 |        1.3 | 4.8e-07 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DataSah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSah>

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
