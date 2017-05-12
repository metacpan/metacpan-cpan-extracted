package Bencher::Scenario::DataSahVSTypeTiny::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

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

This document describes version 0.002 of Bencher::Scenario::DataSahVSTypeTiny::Startup (from Perl distribution Bencher-Scenarios-DataSahVSTypeTiny), released on 2017-01-25.

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSahVSTypeTiny::Startup >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | genv_dsah   |        18 |      55   |        1   | 9.7e-05 |      20 |
 | genv_tt     |        28 |      36   |        1.5 | 9.3e-05 |      22 |
 | load_tt     |        56 |      18   |        3   | 8.1e-05 |      21 |
 | load_dsah   |        86 |      12   |        4.7 | 6.5e-05 |      20 |
 | perl        |       180 |       5.4 |       10   | 2.8e-05 |      20 |
 +-------------+-----------+-----------+------------+---------+---------+


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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
