package Bencher::Scenario::Words2NumsModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various words-to-numbers modules '.
        'of different languages against one another',
    participants => [
        {
            fcall_template => 'Lingua::ID::Words2Nums::words2nums(<word>)',
            tags => ["id"],
        },
        {
            fcall_template => 'Lingua::EN::Words2Nums::words2nums(<word>)',
            tags => ["en"],
        },
    ],
    datasets => [
        {name=>"en_1"        , args=>{word=>"one"}, include_participant_tags => ["en"]},
        {name=>"en_123"      , args=>{word=>"one hundred and twenty three"}, include_participant_tags => ["en"]},
        {name=>"en_123456789", args=>{word=>"one hundred and twenty three million, four hundred and fifty six thousand, seven hundred and eighty nine"}, include_participant_tags => ["en"]},

        {name=>"id_1"        , args=>{word=>"satu"}, include_participant_tags => ["id"]},
        {name=>"id_123"      , args=>{word=>"seratus dua puluh tiga"}, include_participant_tags => ["id"]},
        {name=>"id_123456789", args=>{word=>"seratus dua puluh tiga juta empat ratus lima puluh enam ribu tujuh ratus delapan puluh sembilan"}, include_participant_tags => ["id"]},
    ],
};

1;
# ABSTRACT: Benchmark various words-to-numbers modules of different languages against one another

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Words2NumsModules - Benchmark various words-to-numbers modules of different languages against one another

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Words2NumsModules (from Perl distribution Bencher-Scenario-Words2NumsModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Words2NumsModules

To run module startup overhead benchmark:

 % bencher --module-startup -m Words2NumsModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Lingua::ID::Words2Nums> 0.17

L<Lingua::EN::Words2Nums>

=head1 BENCHMARK PARTICIPANTS

=over

=item * Lingua::ID::Words2Nums::words2nums (perl_code) [id]

Function call template:

 Lingua::ID::Words2Nums::words2nums(<word>)



=item * Lingua::EN::Words2Nums::words2nums (perl_code) [en]

Function call template:

 Lingua::EN::Words2Nums::words2nums(<word>)



=back

=head1 BENCHMARK DATASETS

=over

=item * en_1

=item * en_123

=item * en_123456789

=item * id_1

=item * id_123

=item * id_123456789

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Words2NumsModules >>):

 #table1#
 +------------------------------------+--------------+------------+-----------+------------+---------+---------+
 | participant                        | dataset      | rate (/s)  | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+--------------+------------+-----------+------------+---------+---------+
 | Lingua::ID::Words2Nums::words2nums | id_123456789 |   5540.363 |  180.4936 |    1       | 1.1e-11 |      20 |
 | Lingua::EN::Words2Nums::words2nums | en_123456789 |  16649.7   |   60.0611 |    3.00516 |   0     |      20 |
 | Lingua::ID::Words2Nums::words2nums | id_123       |  38486     |   25.9835 |    6.94648 |   0     |      20 |
 | Lingua::EN::Words2Nums::words2nums | en_123       |  82900     |   12.1    |   15       | 3.3e-09 |      21 |
 | Lingua::ID::Words2Nums::words2nums | id_1         | 160000     |    6.4    |   28       | 1.3e-08 |      20 |
 | Lingua::EN::Words2Nums::words2nums | en_1         | 310000     |    3.2    |   56       |   5e-09 |      20 |
 +------------------------------------+--------------+------------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m Words2NumsModules --module-startup >>):

 #table2#
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant            | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Lingua::ID::Words2Nums | 1.1                          | 4.7                | 16             |        11 |                      6 |        1   | 3.7e-05 |      20 |
 | Lingua::EN::Words2Nums | 0.82                         | 4                  | 16             |        10 |                      5 |        1.1 | 5.6e-05 |      20 |
 | perl -e1 (baseline)    | 1.3                          | 4.8                | 18             |         5 |                      0 |        2.2 | 1.5e-05 |      20 |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Words2NumsModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Words2NumsModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Words2NumsModules>

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
