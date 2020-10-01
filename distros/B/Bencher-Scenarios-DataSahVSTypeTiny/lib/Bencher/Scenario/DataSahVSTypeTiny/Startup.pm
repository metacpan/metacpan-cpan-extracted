package Bencher::Scenario::DataSahVSTypeTiny::Startup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-01'; # DATE
our $DIST = 'Bencher-Scenarios-DataSahVSTypeTiny'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark startup',
    participants => [
        {
            name => 'perl',
            perl_cmdline => ["-e1"],
        },
        {
            name => 'load_dsah',
            summary => 'Load Data::Sah',
            perl_cmdline => ["-MData::Sah", "-e1"],
        },
        {
            name => 'load_tt',
            summary => 'Load Type::Tiny',
            perl_cmdline => ["-MType::Tiny", "-e1"],
        },
        {
            name => 'genv_dsah',
            summary => 'Generate validator (int*) with Data::Sah',
            perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'gen_validator("int*")'],
        },
        {
            name => 'genv_tt',
            summary => 'Generate validator (Int) with Type::Tiny',
            perl_cmdline => ["-MTypes::Standard=Int", "-e1"],
        },
    ],
};

1;
# ABSTRACT: Benchmark startup

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSahVSTypeTiny::Startup - Benchmark startup

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::DataSahVSTypeTiny::Startup (from Perl distribution Bencher-Scenarios-DataSahVSTypeTiny), released on 2020-10-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSahVSTypeTiny::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (command)



=item * load_dsah (command)

Load Data::Sah.



=item * load_tt (command)

Load Type::Tiny.



=item * genv_dsah (command)

Generate validator (int*) with Data::Sah.



=item * genv_tt (command)

Generate validator (Int) with Type::Tiny.



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m DataSahVSTypeTiny::Startup >>):

 #table1#
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | genv_dsah   |      14.4 |      69.6 |                 0.00% |               576.26% | 5.4e-05 |      21 |
 | genv_tt     |      20   |      50   |                38.53% |               388.19% | 6.6e-05 |      21 |
 | load_tt     |      39   |      26   |               170.66% |               149.85% | 3.5e-05 |      20 |
 | load_dsah   |      60   |      17   |               319.92% |                61.05% | 5.4e-05 |      20 |
 | perl        |      97   |      10   |               576.26% |                 0.00% | 6.3e-05 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSahVSTypeTiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataSahVSTypeTiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSahVSTypeTiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
