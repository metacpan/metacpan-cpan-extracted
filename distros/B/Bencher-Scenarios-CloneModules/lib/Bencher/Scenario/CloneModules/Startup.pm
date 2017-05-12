package Bencher::Scenario::CloneModules::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

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

This document describes version 0.04 of Bencher::Scenario::CloneModules::Startup (from Perl distribution Bencher-Scenarios-CloneModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CloneModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Clone> 0.38

L<Clone::PP> 1.06

L<Clone::Util> 0.03

L<Data::Clone> 0.004

L<Function::Fallback::CoreOrPP> 0.08

L<Sereal::Dclone> 0.002

L<Storable> 2.56

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark cloning a 10k-element array (C<< bencher -m CloneModules::Startup --include-datasets array10k >>):

 #table1#
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                  | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Storable                     | 0.8                          | 4                  | 20             |      20   |                   13.9 |        1   |   0.00053 |      20 |
 | Sereal::Dclone               | 2                            | 5                  | 20             |      20   |                   13.9 |        1   |   0.00037 |      20 |
 | Clone                        | 1                            | 4.4                | 16             |      12   |                    5.9 |        2   | 4.5e-05   |      22 |
 | Data::Clone                  | 0.96                         | 4.3                | 16             |      11   |                    4.9 |        2.2 | 5.1e-05   |      20 |
 | Clone::PP                    | 0.98                         | 4.3                | 16             |      10   |                    3.9 |        2.4 | 4.3e-05   |      20 |
 | Clone::Util                  | 1.1                          | 4.4                | 18             |      10   |                    3.9 |        2.4 | 4.6e-05   |      20 |
 | Function::Fallback::CoreOrPP | 1.5                          | 5.3                | 21             |       9.9 |                    3.8 |        2.4 | 5.1e-05   |      20 |
 | perl -e1 (baseline)          | 1.3                          | 4.6                | 18             |       6.1 |                    0   |        3.9 | 1.2e-05   |      20 |
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


Benchmark cloning a 10k-pair hash (C<< bencher -m CloneModules::Startup --include-datasets hash10k >>):

 #table2#
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                  | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Sereal::Dclone               | 2                            | 5                  | 20             |        20 |                     10 |        1   | 0.00068 |      20 |
 | Clone                        | 1                            | 4                  | 20             |        20 |                     10 |        1   | 0.00057 |      20 |
 | Storable                     | 0.82                         | 4.1                | 16             |        16 |                      6 |        1.3 | 9e-05   |      20 |
 | Clone::PP                    | 1                            | 4                  | 20             |        20 |                     10 |        1   | 0.00036 |      20 |
 | Clone::Util                  | 1                            | 5                  | 20             |        20 |                     10 |        1   | 0.0003  |      20 |
 | Data::Clone                  | 0.96                         | 4.3                | 16             |        13 |                      3 |        1.6 | 0.00012 |      20 |
 | Function::Fallback::CoreOrPP | 2                            | 5                  | 20             |        10 |                      0 |        2   | 0.00015 |      20 |
 | perl -e1 (baseline)          | 1                            | 5                  | 20             |        10 |                      0 |        2   | 0.00027 |      21 |
 +------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
