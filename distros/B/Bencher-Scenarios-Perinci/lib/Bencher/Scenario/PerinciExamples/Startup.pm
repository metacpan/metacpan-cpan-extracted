package Bencher::Scenario::PerinciExamples::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of Perinci::Examples modules',
    modules => {
        # minimum versions
        'Perinci::Examples' => {version=>'0.79'},
        'Perinci::Examples::Tiny' => {version=>'0.79'},
    },
    module_startup => 1,
    participants => [
        {module=>'Perinci::Examples'},
        {module=>'Perinci::Examples::Tiny'},
        {module=>'Perinci::Examples::CLI'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of Perinci::Examples modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciExamples::Startup - Benchmark startup overhead of Perinci::Examples modules

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::PerinciExamples::Startup (from Perl distribution Bencher-Scenarios-Perinci), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciExamples::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Examples> 0.79

L<Perinci::Examples::CLI> 0.79

L<Perinci::Examples::Tiny> 0.79

=head1 BENCHMARK PARTICIPANTS

=over

=item * Perinci::Examples (perl_code)

L<Perinci::Examples>



=item * Perinci::Examples::Tiny (perl_code)

L<Perinci::Examples::Tiny>



=item * Perinci::Examples::CLI (perl_code)

L<Perinci::Examples::CLI>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciExamples::Startup >>):

 #table1#
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant             | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Perinci::Examples       | 0.89                         | 4.2                | 16             |      16   |                   10.2 |        1   | 8.7e-05 |      20 |
 | Perinci::Examples::CLI  | 0.82                         | 4.1                | 16             |       8.5 |                    2.7 |        1.9 | 2.9e-05 |      20 |
 | Perinci::Examples::Tiny | 0.89                         | 4.2                | 16             |       6.5 |                    0.7 |        2.5 | 2.4e-05 |      21 |
 | perl -e1 (baseline)     | 1.9                          | 5.4                | 21             |       5.8 |                    0   |        2.8 | 2.2e-05 |      20 |
 +-------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Perinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Perinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Perinci>

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
