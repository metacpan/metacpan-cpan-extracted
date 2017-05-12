package Bencher::Scenario::DataSah::extract_subschemas;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.07'; # VERSION

our $scenario = {
    summary => 'Benchmark extracting subschemas',
    participants => [
        {
            fcall_template => 'Data::Sah::Util::Subschema::extract_subschemas(<schema>)',
            result_is_list => 1,
        },
    ],
    datasets => [

        {
            args    => {
                schema => 'int',
            },
        },

        {
            args => {
                schema => [array => of=>"int"],
            },
        },

        {
            args => {
                schema => [any => of => ["int*", [array => of=>"int"]]],
            },
        },

        {
            args => {
                schema => [array => "of|"=>["int","float"]],
            },
        },

    ],
};

1;
# ABSTRACT: Benchmark extracting subschemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSah::extract_subschemas - Benchmark extracting subschemas

=head1 VERSION

This document describes version 0.07 of Bencher::Scenario::DataSah::extract_subschemas (from Perl distribution Bencher-Scenarios-DataSah), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSah::extract_subschemas

To run module startup overhead benchmark:

 % bencher --module-startup -m DataSah::extract_subschemas

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah::Util::Subschema> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Sah::Util::Subschema::extract_subschemas (perl_code)

Function call template:

 Data::Sah::Util::Subschema::extract_subschemas(<schema>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int

=item * ["array","of","int"]

=item * ["any","of",["int*",["array","of","int"]]]

=item * ["array","of|",["int","float"]]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSah::extract_subschemas >>):

 #table1#
 +--------------------------------------------+-----------+-----------+------------+---------+---------+
 | dataset                                    | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------------------------------+-----------+-----------+------------+---------+---------+
 | ["any","of",["int*",["array","of","int"]]] |     17000 |      57   |        1   | 1.1e-07 |      20 |
 | ["array","of|",["int","float"]]            |     27000 |      37   |        1.5 | 5.3e-08 |      20 |
 | ["array","of","int"]                       |     36000 |      28   |        2.1 | 9.7e-08 |      24 |
 | int                                        |    150000 |       6.7 |        8.5 | 1.3e-08 |      20 |
 +--------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataSah::extract_subschemas --module-startup >>):

 #table2#
 +----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Data::Sah::Util::Subschema | 0.82                         | 4.1                | 16             |        10 |                      3 |          1 | 5e-05   |      21 |
 | perl -e1 (baseline)        | 1                            | 4                  | 20             |         7 |                      0 |          1 | 0.00011 |      21 |
 +----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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
